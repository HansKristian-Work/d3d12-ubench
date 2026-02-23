/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */
#define INITGUID
#include "device.hpp"
#include "logging.hpp"
#include <assert.h>
#include <stdexcept>
#include <thread>
#include <chrono>

#ifdef _WIN32
#define dlopen(path, mode) (void *)LoadLibraryA(path)
#define dlsym(module, sym) (void *)GetProcAddress((HMODULE)module, sym)
#include <sys/stat.h>
#include <sys/types.h>
#else
#include <dlfcn.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#endif

void FrameContext::reset()
{
	if (FAILED(allocator->Reset()))
		LOGE("Failed to reset allocator.\n");
	for (auto &def : deferred)
		def();
	deferred.clear();
	work_index = 0;

	const uint64_t *ptr = nullptr;
	if (FAILED(timestamp_readback->Map(0, nullptr, (void **)&ptr)))
		return;

	for (size_t i = 0, n = timestamp_callbacks.size(); i < n; i++)
	{
		if (timestamp_callbacks[i])
		{
			uint64_t delta = ptr[2 * i + 1] - ptr[2 * i + 0];
			timestamp_callbacks[i](delta * 1000000000ull / timestamp_freq);
		}
	}
	timestamp_callbacks.clear();

	timestamp_readback->Unmap(0, nullptr);
	held.clear();
}

bool Device::compile_compute_shader(PipelineState &state)
{
	if (state.root_signature)
		return state.pso.get() != nullptr;

	if (!state.bytecode_size)
		return false;

	LOGI("Compiling shader %s\n", state.name);

	if (FAILED(device->CreateRootSignature(0, state.bytecode, state.bytecode_size, IID_ID3D12RootSignature, state.root_signature.ppv())))
	{
		LOGE("Failed to create root signature.\n");
		return false;
	}

	D3D12_COMPUTE_PIPELINE_STATE_DESC desc = {};
	desc.pRootSignature = state.root_signature.get();
	desc.CS.pShaderBytecode = state.bytecode;
	desc.CS.BytecodeLength = state.bytecode_size;

	if (FAILED(device->CreateComputePipelineState(&desc, IID_ID3D12PipelineState, state.pso.ppv())))
	{
		LOGE("Failed to create PSO.\n");
		return false;
	}

	LOGI(" ... done\n");

	if (state.name)
	{
		WCHAR wname[1024] = {};
		int index = 0;
		for (auto *ptr = state.name; *ptr != '\0'; ptr++, index++)
			wname[index] = WCHAR(uint8_t(*ptr));
		state.pso->SetName(wname);
	}

	return true;
}

void Device::wait_idle()
{
	queue->Signal(fence.get(), ++latest_fence_value);
	fence->SetEventOnCompletion(latest_fence_value, nullptr);
	for (auto &ctx : frame_contexts)
		ctx.reset();
}

FrameContext &Device::get_frame_context()
{
	return frame_contexts[frame_index];
}

void Device::mark(ComPtr<ID3D12DeviceChild> held)
{
	get_frame_context().held.push_back(std::move(held));
}

void Device::defer(std::function<void()> func)
{
	get_frame_context().deferred.push_back(std::move(func));
}

void Device::next_frame_context()
{
	frame_index = (frame_index + 1) % NumFrameContexts;

	auto &ctx = frame_contexts[frame_index];

	if (FAILED(fence->SetEventOnCompletion(ctx.fence_value_for_iteration, nullptr)))
		LOGE("Failed to wait for event.\n");
	ctx.reset();
}

ID3D12GraphicsCommandList *Device::begin_work()
{
	assert(!in_work);
	if (in_work)
		return nullptr;

	auto &ctx = get_frame_context();
	list->Reset(ctx.allocator.get(), nullptr);
	ID3D12DescriptorHeap *heaps[] = { resource_heap.get(), sampler_heap.get() };
	list->SetDescriptorHeaps(2, heaps);
	list->EndQuery(ctx.timestamps.get(), D3D12_QUERY_TYPE_TIMESTAMP, 2 * ctx.work_index + 0);
	in_work = true;
	return list.get();
}

#define ASSERT_IN_WORK() do { \
	if (!in_work) std::terminate(); \
} while(false)

#define ASSERT_OUTSIDE_WORK() do { \
	if (in_work) std::terminate(); \
} while(false)

bool Device::setup_compute(PipelineState &pso)
{
	// Lazily compile.
	if (!compile_compute_shader(pso))
		return false;

	ASSERT_IN_WORK();
	list->SetComputeRootSignature(pso.root_signature.get());
	list->SetPipelineState(pso.pso.get());
	return true;
}

void Device::dispatch(uint32_t x, uint32_t y, uint32_t z)
{
	ASSERT_IN_WORK();
	list->Dispatch(x, y, z);
}

void Device::set_resource_table(uint32_t index, uint32_t heap_index)
{
	ASSERT_IN_WORK();
	auto h = resource_heap->GetGPUDescriptorHandleForHeapStart();
	h.ptr += heap_index * device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
	list->SetComputeRootDescriptorTable(index, h);
}

void Device::set_sampler_table(uint32_t index, uint32_t heap_index)
{
	ASSERT_IN_WORK();
	auto h = sampler_heap->GetGPUDescriptorHandleForHeapStart();
	h.ptr += heap_index * device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
	list->SetComputeRootDescriptorTable(index, h);
}

void Device::set_root_cbv(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va)
{
	list->SetComputeRootConstantBufferView(index, va);
}

void Device::set_root_uav(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va)
{
	list->SetComputeRootUnorderedAccessView(index, va);
}

void Device::set_root_srv(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va)
{
	list->SetComputeRootShaderResourceView(index, va);
}

void Device::set_constant(uint32_t index, uint32_t offset, uint32_t value)
{
	list->SetComputeRoot32BitConstant(index, value, offset);
}

void Device::set_constants(uint32_t index, const uint32_t *values, uint32_t count)
{
	list->SetComputeRoot32BitConstants(index, count, values, 0);
}

void Device::create_sampler(uint32_t index, const D3D12_SAMPLER_DESC *desc)
{
	auto ptr = sampler_heap->GetCPUDescriptorHandleForHeapStart();
	ptr.ptr += index * device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
	device->CreateSampler(desc, ptr);
}

void Device::create_srv(uint32_t index, ID3D12Resource *res, const D3D12_SHADER_RESOURCE_VIEW_DESC *desc)
{
	auto ptr = resource_heap->GetCPUDescriptorHandleForHeapStart();
	ptr.ptr += index * device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
	device->CreateShaderResourceView(res, desc, ptr);
}

void Device::create_cbv(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va, uint32_t size)
{
	D3D12_CONSTANT_BUFFER_VIEW_DESC cbv = {};
	auto ptr = resource_heap->GetCPUDescriptorHandleForHeapStart();
	ptr.ptr += index * device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
	cbv.BufferLocation = va;
	cbv.SizeInBytes = size;
	device->CreateConstantBufferView(&cbv, ptr);
}

void Device::create_uav(uint32_t index, ID3D12Resource *res, const D3D12_UNORDERED_ACCESS_VIEW_DESC *desc)
{
	auto ptr = resource_heap->GetCPUDescriptorHandleForHeapStart();
	ptr.ptr += index * device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
	device->CreateUnorderedAccessView(res, nullptr, desc, ptr);
}

bool Device::end_work(std::function<void (uint64_t)> ts_callback)
{
	assert(in_work);
	if (!in_work)
		return false;
	in_work = false;

	auto &ctx = get_frame_context();
	ctx.timestamp_callbacks.push_back(std::move(ts_callback));
	list->EndQuery(ctx.timestamps.get(), D3D12_QUERY_TYPE_TIMESTAMP, 2 * ctx.work_index + 1);
	list->ResolveQueryData(ctx.timestamps.get(), D3D12_QUERY_TYPE_TIMESTAMP, 2 * ctx.work_index, 2,
	                       ctx.timestamp_readback.get(), 2 * sizeof(uint64_t) * ctx.work_index);
	list->Close();
	ID3D12CommandList *l = list.get();
	queue->ExecuteCommandLists(1, &l);
	queue->Signal(fence.get(), ++latest_fence_value);
	ctx.fence_value_for_iteration = latest_fence_value;
	ctx.work_index++;

	if (ctx.work_index >= FrameContext::NumRegionsPerFrameContext)
		next_frame_context();

	return true;
}

bool Device::end_work_with_defer(std::function<void()> cb)
{
	defer(std::move(cb));
	return end_work({});
}

template<typename Op>
void Device::scoped_work(const Op &op)
{
	bool new_scope = !in_work;
	if (new_scope)
		begin_work();
	op();
	if (new_scope)
		end_work({});
}

void Device::copy_buffer(ID3D12Resource *dst, uint64_t dst_offset, ID3D12Resource *src, uint64_t src_offset, uint64_t size)
{
	mark(ComPtr<ID3D12DeviceChild>::addref(dst));
	mark(ComPtr<ID3D12DeviceChild>::addref(src));
	scoped_work([&]() { list->CopyBufferRegion(dst, dst_offset, src, src_offset, size); });
}

void Device::copy_buffer_to_texture(ID3D12Resource *dst, uint32_t dst_subresource, ID3D12Resource *src, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)
{
	mark(ComPtr<ID3D12DeviceChild>::addref(dst));
	mark(ComPtr<ID3D12DeviceChild>::addref(src));

	scoped_work([&]()
	{
		D3D12_TEXTURE_COPY_LOCATION dst_region = {}, src_region = {};
		dst_region.pResource = dst;
		dst_region.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dst_region.SubresourceIndex = dst_subresource;

		src_region.pResource = src;
		src_region.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		src_region.PlacedFootprint = footprint;
		list->CopyTextureRegion(&dst_region, 0, 0, 0, &src_region, nullptr);
	});
}

void Device::copy_texture_to_buffer(ID3D12Resource *dst, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint,
                                    ID3D12Resource *src, uint32_t src_subresource)
{
	mark(ComPtr<ID3D12DeviceChild>::addref(dst));
	mark(ComPtr<ID3D12DeviceChild>::addref(src));

	scoped_work([&]()
	{
		D3D12_TEXTURE_COPY_LOCATION dst_region = {}, src_region = {};
		src_region.pResource = src;
		src_region.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		src_region.SubresourceIndex = src_subresource;

		dst_region.pResource = dst;
		dst_region.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		dst_region.PlacedFootprint = footprint;
		list->CopyTextureRegion(&dst_region, 0, 0, 0, &src_region, nullptr);
	});
}

void Device::transition_resource(ID3D12Resource *resource, D3D12_RESOURCE_STATES before, D3D12_RESOURCE_STATES after)
{
	mark(ComPtr<ID3D12DeviceChild>::addref(resource));

	scoped_work([&]()
	{
		D3D12_RESOURCE_BARRIER barr = {};
		barr.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barr.Transition.pResource = resource;
		barr.Transition.StateBefore = before;
		barr.Transition.StateAfter = after;
		barr.Transition.Subresource = UINT32_MAX;
		list->ResourceBarrier(1, &barr);
	});
}

void Device::uav_barrier()
{
	scoped_work([&]()
	{
		D3D12_RESOURCE_BARRIER barr = {};
		barr.Type = D3D12_RESOURCE_BARRIER_TYPE_UAV;
		list->ResourceBarrier(1, &barr);
	});
}

ComPtr<ID3D12Resource> Device::create_generic_buffer(
	D3D12_HEAP_TYPE heap_type, uint64_t size, const void *data,
	D3D12_RESOURCE_FLAGS flags, D3D12_RESOURCE_STATES state)
{
	D3D12_RESOURCE_DESC desc = {};
	desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	desc.Width = size;
	desc.Height = 1;
	desc.DepthOrArraySize = 1;
	desc.MipLevels = 1;
	desc.SampleDesc.Count = 1;
	desc.Flags = flags;

	D3D12_HEAP_PROPERTIES heap_props = {};
	ComPtr<ID3D12Resource> resource;

	auto init_state = data && heap_type == D3D12_HEAP_TYPE_DEFAULT ? D3D12_RESOURCE_STATE_COPY_DEST : state;

	heap_props.Type = heap_type;
	if (FAILED(device->CreateCommittedResource(&heap_props, D3D12_HEAP_FLAG_NONE, &desc, init_state,
		nullptr, IID_ID3D12Resource, resource.ppv())))
		return {};

	if (data)
	{
		if (heap_type == D3D12_HEAP_TYPE_UPLOAD || heap_type == D3D12_HEAP_TYPE_READBACK)
		{
			void *map_ptr;
			if (FAILED(resource->Map(0, nullptr, &map_ptr)))
				return {};
			memcpy(map_ptr, data, size);
			resource->Unmap(0, nullptr);
		}
		else if (heap_type == D3D12_HEAP_TYPE_DEFAULT)
		{
			ASSERT_OUTSIDE_WORK();
			auto upload_buffer = create_upload_buffer(size, data);
			copy_buffer(resource.get(), 0, upload_buffer.get(), 0, size);
			if (init_state != state)
				transition_resource(resource.get(), init_state, state);
		}
		else
			return {};
	}

	return resource;
}

ComPtr<ID3D12Resource> Device::create_texture2d(
	DXGI_FORMAT format, uint32_t width, uint32_t height,
	uint32_t layers, uint32_t levels,
	D3D12_RESOURCE_FLAGS flags, D3D12_RESOURCE_STATES state,
	const InitialTextureData *initial)
{
	D3D12_RESOURCE_DESC desc = {};
	desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
	desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
	desc.Width = width;
	desc.Height = height;
	desc.Format = format;
	desc.DepthOrArraySize = layers;
	desc.MipLevels = levels;
	desc.SampleDesc.Count = 1;
	desc.Flags = flags;

	D3D12_HEAP_PROPERTIES heap_props = {};
	ComPtr<ID3D12Resource> resource;

	auto init_state = initial ? D3D12_RESOURCE_STATE_COPY_DEST : state;

	heap_props.Type = D3D12_HEAP_TYPE_DEFAULT;
	if (FAILED(device->CreateCommittedResource(&heap_props, D3D12_HEAP_FLAG_NONE, &desc, init_state,
		nullptr, IID_ID3D12Resource, resource.ppv())))
		return {};

	if (initial)
	{
		ASSERT_OUTSIDE_WORK();
		D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint;
		UINT64 total_bytes;
		UINT64 row_size;
		device->GetCopyableFootprints(&desc, 0, 1, 0,
		                              &footprint, nullptr, &row_size, &total_bytes);

		auto upload_buffer = create_upload_buffer(total_bytes, nullptr);
		if (!upload_buffer)
			return {};

		uint8_t *mapped;
		if (FAILED(upload_buffer->Map(0, nullptr, (void **)&mapped)))
			return {};

		for (uint32_t y = 0; y < height; y++)
		{
			memcpy(mapped + footprint.Offset + footprint.Footprint.RowPitch * y,
			       static_cast<const uint8_t *>(initial->data) + initial->row_pitch * y,
			       row_size);
		}

		upload_buffer->Unmap(0, nullptr);
		copy_buffer_to_texture(resource.get(), 0, upload_buffer.get(), footprint);
		if (init_state != state)
			transition_resource(resource.get(), init_state, state);
	}

	return resource;
}

ComPtr<ID3D12Resource> Device::create_readback_buffer(uint64_t size)
{
	return create_generic_buffer(D3D12_HEAP_TYPE_READBACK, size, nullptr, D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_COPY_DEST);
}

ComPtr<ID3D12Resource> Device::create_upload_buffer(uint64_t size, const void *data)
{
	return create_generic_buffer(D3D12_HEAP_TYPE_UPLOAD, size, data, D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_GENERIC_READ);
}

ComPtr<ID3D12Resource> Device::create_default_buffer(uint64_t size, const void *data, D3D12_RESOURCE_FLAGS flags, D3D12_RESOURCE_STATES state)
{
	return create_generic_buffer(D3D12_HEAP_TYPE_DEFAULT, size, data, flags, state);
}

void Device::async_readback(ID3D12Resource *src, uint32_t src_subresource,
	std::function<void(const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)> func)
{
	ASSERT_OUTSIDE_WORK();
	if (src->GetDesc().Dimension == D3D12_RESOURCE_DIMENSION_BUFFER)
	{
		auto readback = create_readback_buffer(src->GetDesc().Width);
		begin_work();
		copy_buffer(readback.get(), 0, src, 0, src->GetDesc().Width);
		end_work_with_defer([=]() mutable
		{
			uint8_t *ptr;
			if (SUCCEEDED(readback->Map(0, nullptr, (void **)&ptr)))
			{
				D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint = {};
				footprint.Footprint.Width = src->GetDesc().Width;
				footprint.Footprint.RowPitch = footprint.Footprint.Width;
				footprint.Footprint.Height = 1;
				footprint.Footprint.Depth = 1;
				func(ptr, footprint);
			}
			readback->Unmap(0, nullptr);
		});
	}
	else
	{
		auto desc = src->GetDesc();
		D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint;
		UINT64 total_bytes;
		device->GetCopyableFootprints(&desc, src_subresource, 1, 0, &footprint, nullptr, nullptr, &total_bytes);
		auto readback = create_readback_buffer(total_bytes);

		begin_work();
		copy_texture_to_buffer(readback.get(), footprint, src, src_subresource);
		end_work_with_defer([=]() mutable
		{
			uint8_t *ptr;
			if (SUCCEEDED(readback->Map(0, nullptr, (void **)&ptr)))
				func(ptr, footprint);
			readback->Unmap(0, nullptr);
		});
	}
}

bool Device::init(const std::string &path, bool validate, bool vkd3d_proton)
{
#ifndef VKD3D_PROTON_SYSTEM
	void *module = dlopen(path.c_str(), RTLD_NOW);
	if (!module)
	{
		LOGE("Failed to load vkd3d-proton.\n");
		return false;
	}

	// For convenience on Windows build, we just load d3d12core.dll directly and extract the private APIs.
	if (vkd3d_proton)
	{
		auto get_interface = (PFN_D3D12_GET_INTERFACE) dlsym(module, "D3D12GetInterface");
		if (!get_interface)
			return false;

		IVKD3DCoreInterface *iface;
		if (FAILED(get_interface(CLSID_VKD3DCore, IID_IVKD3DCoreInterface, (void **)&iface)))
		{
			LOGE("%s does not look like a vkd3d-proton d3d12core.dll.\n", path.c_str());
			return false;
		}

		if (FAILED(iface->CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_ID3D12Device, device.ppv())))
		{
			fprintf(stderr, "Failed to create device.\n");
			return false;
		}
	}
	else
	{
		if (validate)
		{
			auto get_debug_iface = (PFN_D3D12_GET_DEBUG_INTERFACE) dlsym(module, "D3D12GetDebugInterface");
			ComPtr<ID3D12Debug> debug;
			if (SUCCEEDED(get_debug_iface(IID_ID3D12Debug, debug.ppv())))
			{
				LOGI("Enabling validation.\n");
				debug->EnableDebugLayer();
			}
		}

		auto create = (PFN_D3D12_CREATE_DEVICE) dlsym(module, "D3D12CreateDevice");
		if (!create)
		{
			LOGE("Failed to query symbol.\n");
			return false;
		}

		if (FAILED(create(nullptr, D3D_FEATURE_LEVEL_12_0, IID_ID3D12Device, device.ppv())))
		{
			fprintf(stderr, "Failed to create device.\n");
			return false;
		}
	}
#else
	(void)path;
	(void)validate;
	if (FAILED(D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_ID3D12Device, device.ppv())))
	{
		fprintf(stderr, "Failed to create device.\n");
		return {};
	}
#endif

	auto *dev = device.get();

	if (FAILED(dev->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_ID3D12Fence, fence.ppv())))
		return false;

	D3D12_COMMAND_QUEUE_DESC desc = {};
	desc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
	if (FAILED(dev->CreateCommandQueue(&desc, IID_ID3D12CommandQueue, queue.ppv())))
		return false;

	UINT64 freq;
	queue->GetTimestampFrequency(&freq);

	for (auto &ctx : frame_contexts)
	{
		if (FAILED(dev->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_ID3D12CommandAllocator, ctx.allocator.ppv())))
			return false;
		ctx.timestamp_freq = freq;
		ctx.timestamp_readback = create_readback_buffer(FrameContext::NumRegionsPerFrameContext * sizeof(uint64_t) * 2);
		if (!ctx.timestamp_readback)
			return false;

		D3D12_QUERY_HEAP_DESC query_heap_desc = {};
		query_heap_desc.Type = D3D12_QUERY_HEAP_TYPE_TIMESTAMP;
		query_heap_desc.Count = FrameContext::NumRegionsPerFrameContext * 2;
		if (FAILED(dev->CreateQueryHeap(&query_heap_desc, IID_ID3D12QueryHeap, ctx.timestamps.ppv())))
			return false;
	}

	if (FAILED(dev->CreateCommandList(
			0, D3D12_COMMAND_LIST_TYPE_DIRECT, frame_contexts[0].allocator.get(),
			nullptr, IID_ID3D12CommandList, list.ppv())))
	{
		return false;
	}

	D3D12_DESCRIPTOR_HEAP_DESC heap_desc = {};
	heap_desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;

	heap_desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
	heap_desc.NumDescriptors = 1000000;
	if (FAILED(dev->CreateDescriptorHeap(&heap_desc, IID_ID3D12DescriptorHeap, resource_heap.ppv())))
		return false;

	heap_desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER;
	heap_desc.NumDescriptors = 2048;
	if (FAILED(dev->CreateDescriptorHeap(&heap_desc, IID_ID3D12DescriptorHeap, sampler_heap.ppv())))
		return false;

	list->Close();

#ifdef _WIN32
	void *rdoc = GetModuleHandleA("renderdoc.dll");
#else
	void *rdoc = dlopen("librenderdoc.so", RTLD_NOW | RTLD_NOLOAD);
#endif

	if (rdoc)
	{
		auto get_api = (pRENDERDOC_GetAPI)dlsym(rdoc, "RENDERDOC_GetAPI");
		if (get_api)
			if (!get_api(eRENDERDOC_API_Version_1_0_0, (void **)&renderdoc_api))
				renderdoc_api = nullptr;

		if (renderdoc_api)
		{
			int major, minor, patch;
			renderdoc_api->GetAPIVersion(&major, &minor, &patch);
			LOGI("Initializing RenderDoc API version %d.%d.%d\n", major, minor, patch);
		}
	}

	return true;
}

void Device::begin_renderdoc_capture()
{
	if (renderdoc_api)
		renderdoc_api->StartFrameCapture(nullptr, nullptr);
}

void Device::end_renderdoc_capture()
{
	if (renderdoc_api)
	{
		renderdoc_api->EndFrameCapture(nullptr, nullptr);

		// D3D12 workaround. Can't exit the process too early.
		std::this_thread::sleep_for(std::chrono::milliseconds(100));
	}
}

bool Device::supports_native_16bit()
{
	D3D12_FEATURE_DATA_D3D12_OPTIONS4 features4 = {};
	return SUCCEEDED(device->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS4, &features4, sizeof(features4))) &&
	       features4.Native16BitShaderOpsSupported;
}

void Device::clear_resource_heap()
{
	// Proxy for any resource.
	for (unsigned i = 0; i < 1000000; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Format = DXGI_FORMAT_R32_UINT;
		create_srv(i, nullptr, &srv_desc);
	}
}

Device::~Device()
{
	if (device)
		wait_idle();
}