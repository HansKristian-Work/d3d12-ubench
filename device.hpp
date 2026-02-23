/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */
#pragma once

#ifdef _MSC_VER
#define __C89_NAMELESS
#define __C89_NAMELESSUNIONNAME
#endif

#include "com_ptr.hpp"
#include <stddef.h>
#include <stdint.h>
#include <vector>
#include <functional>
#include <string>

#include "vkd3d_windows.h"
#include "vkd3d_d3d12.h"
#include "vkd3d_d3d12sdklayers.h"
#include "vkd3d_core_interface.h"

#include "renderdoc_app.h"

struct PipelineState
{
	ComPtr<ID3D12PipelineState> pso;
	ComPtr<ID3D12RootSignature> root_signature;
	const char *name = nullptr;
	const void *bytecode = nullptr;
	size_t bytecode_size = 0;

	PipelineState() = default;
	void operator=(const PipelineState &) = delete;
	PipelineState(const PipelineState &) = delete;
	PipelineState(PipelineState &&) noexcept = default;
	PipelineState &operator=(PipelineState &&) noexcept = default;
};

struct FrameContext
{
	enum { NumRegionsPerFrameContext = 16 };
	ComPtr<ID3D12CommandAllocator> allocator;
	ComPtr<ID3D12QueryHeap> timestamps;
	ComPtr<ID3D12Resource> timestamp_readback;
	uint64_t fence_value_for_iteration = 0;
	uint32_t pending_timestamps = 0;

	std::vector<ComPtr<ID3D12DeviceChild>> held;
	std::vector<std::function<void ()>> deferred;
	std::vector<std::function<void (uint64_t)>> timestamp_callbacks;

	uint64_t timestamp_freq = 0;
	uint32_t work_index = 0;

	void reset();
};

struct InitialTextureData
{
	const void *data;
	size_t row_pitch;
	size_t slice_pitch;
};

class Device
{
public:
	~Device();
	bool init(const std::string &path, bool validate, bool vkd3d_proton);

	void defer(std::function<void ()> func);
	void mark(ComPtr<ID3D12DeviceChild> held);
	void next_frame_context();
	void wait_idle();

	ID3D12GraphicsCommandList *begin_work();
	bool end_work(std::function<void (uint64_t)> ts_callback);
	bool end_work_with_defer(std::function<void ()> cb);

	// Resource creation.
	ComPtr<ID3D12Resource> create_readback_buffer(uint64_t size);
	ComPtr<ID3D12Resource> create_upload_buffer(uint64_t size, const void *data);
	ComPtr<ID3D12Resource> create_default_buffer(uint64_t size, const void *data,
	                                             D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE,
	                                             D3D12_RESOURCE_STATES state = D3D12_RESOURCE_STATE_COMMON);

	ComPtr<ID3D12Resource> create_texture2d(DXGI_FORMAT format, uint32_t width, uint32_t height,
	                                        uint32_t layers, uint32_t levels,
	                                        D3D12_RESOURCE_FLAGS flags,
	                                        D3D12_RESOURCE_STATES state,
	                                        const InitialTextureData *initial);
	///

	// Helpers
	void copy_buffer(ID3D12Resource *dst, uint64_t dst_offset,
	                 ID3D12Resource *src, uint64_t src_offset, uint64_t size);

	void copy_buffer_to_texture(ID3D12Resource *dst, uint32_t dst_subresource,
	                            ID3D12Resource *src, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint);
	void copy_texture_to_buffer(ID3D12Resource *dst, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint,
								ID3D12Resource *src, uint32_t src_subresource);
	void transition_resource(ID3D12Resource *resource, D3D12_RESOURCE_STATES before, D3D12_RESOURCE_STATES after);
	void uav_barrier();

	void async_readback(ID3D12Resource *src, uint32_t src_subresource,
		std::function<void (const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)> func);

	//// Descriptors.
	void create_srv(uint32_t index, ID3D12Resource *res, const D3D12_SHADER_RESOURCE_VIEW_DESC *desc);
	void create_uav(uint32_t index, ID3D12Resource *res, const D3D12_UNORDERED_ACCESS_VIEW_DESC *desc);
	void create_cbv(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va, uint32_t size);
	void create_sampler(uint32_t index, const D3D12_SAMPLER_DESC *desc);

	// Dispatch interface
	bool setup_compute(PipelineState &pso);
	void dispatch(uint32_t x, uint32_t y, uint32_t z);
	void set_resource_table(uint32_t index, uint32_t heap_index);
	void set_sampler_table(uint32_t index, uint32_t heap_index);
	void set_root_srv(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va);
	void set_root_uav(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va);
	void set_root_cbv(uint32_t index, D3D12_GPU_VIRTUAL_ADDRESS va);
	void set_constant(uint32_t index, uint32_t offset, uint32_t value);
	void set_constants(uint32_t index, const uint32_t *values, uint32_t count);

	bool supports_native_16bit();
	void clear_resource_heap();

	void begin_renderdoc_capture();
	void end_renderdoc_capture();

private:
	FrameContext &get_frame_context();
	ComPtr<ID3D12Device> device;
	ComPtr<ID3D12CommandQueue> queue;
	ComPtr<ID3D12Fence> fence;
	ComPtr<ID3D12GraphicsCommandList> list;
	bool compile_compute_shader(PipelineState &state);

	enum { NumFrameContexts = 4 };
	FrameContext frame_contexts[NumFrameContexts];

	uint32_t frame_index = 0;
	uint64_t latest_fence_value = 0;

	ComPtr<ID3D12DescriptorHeap> resource_heap;
	ComPtr<ID3D12DescriptorHeap> sampler_heap;
	bool in_work = false;

	ComPtr<ID3D12Resource> create_generic_buffer(D3D12_HEAP_TYPE heap_type, uint64_t size, const void *data,
	                                             D3D12_RESOURCE_FLAGS flags, D3D12_RESOURCE_STATES state);

	template <typename Op>
	void scoped_work(const Op &op);

	RENDERDOC_API_1_0_0 *renderdoc_api = nullptr;
};


