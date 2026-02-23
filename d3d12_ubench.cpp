/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

#define NOMINMAX
#define _LARGEFILE_SOURCE

#include "device.hpp"
#include "shaders.hpp"
#include <cmath>
#include <chrono>
#include <regex>

#ifdef _MSC_VER
#define __C89_NAMELESS
#define __C89_NAMELESSUNIONNAME
#endif

#include "vkd3d_windows.h"
#include "vkd3d_d3d12.h"
#include "vkd3d_d3d12sdklayers.h"
#include "vkd3d_core_interface.h"

#include "cli_parser.hpp"
#include "com_ptr.hpp"
#include "logging.hpp"
#include "path_utils.hpp"
#include <string>
#include <vector>
#include <algorithm>
#include <stdint.h>

template <typename T, size_t N>
static constexpr size_t size(const T (&)[N])
{
	return N;
}

static void print_help()
{
	LOGI("d3d12-ubench"
	     "\n\t[--d3d12 <path>] path to d3d12.dll implementation or libvkd3d-proton-d3d12.so"
	     "\n\t[--vkd3d-proton] if this is used, --d3d12 should point to d3d12core.dll or Linux equivalent. For convenience."
	     "\n\t[--validate] enables d3d12 validation layers"
	     "\n\t[--filter-and <regex>] only run specific tests. All filters must pass to run. Can be used multiple times"
	     "\n\t[--filter-negative <regex>] do not run any matching test. Can be used multiple times"
	     "\n\t[--filter-or <regex>] only run specific tests. At least one filter must pass to run. Can be used multiple times"
	     "\n\t[--max-test-seconds <seconds>]"
	     "\n\t[--self-test]"
	     "\n\t[--filter <regex>] alias for --filter-or"
	     "\n");
}

struct Options
{
	std::vector<std::regex> filter_ors;
	std::vector<std::regex> filter_ands;
	std::vector<std::regex> filter_negatives;
	uint32_t min_iterations = 4;
	uint32_t max_iterations = 1024;
	double max_seconds_per_run = 1.0;
	bool verbose = false;
	bool renderdoc = false;
};

struct BenchmarkResult
{
	std::string test;
	double median_time;
	double avg_time;
	double stddev_percentage;
};

struct BenchmarkResults
{
	std::vector<BenchmarkResult> results;
	void add_result(const std::string &test, double median_time, double avg_time, double stddev_percentage);
	std::string generate_csv();
};

static Options options;
static BenchmarkResults results;

void BenchmarkResults::add_result(const std::string &test, double median_time, double avg_time, double stddev_percentage)
{
	results.push_back({ test, median_time, avg_time, stddev_percentage });
}

std::string BenchmarkResults::generate_csv()
{
	std::sort(results.begin(), results.end(), [](const BenchmarkResult &a, const BenchmarkResult &b)
	{
		return a.test.compare(b.test) < 0;
	});

	std::string csv = "test,median,avg,stddev_percentage\n";
	for (auto &res : results)
	{
		char line[256];
		snprintf(line, sizeof(line), "%s,%.6g,%.6g,%.6g\n", res.test.c_str(), res.median_time, res.avg_time, res.stddev_percentage);
		csv += line;
	}

	return csv;
}

static Device device;
static DXIL::Shaders shaders;

#define ASSERT_THAT(x) do { \
	if (!(x)) { LOGE("Failed assertion %s at line %d.\n", #x, __LINE__); } \
} while(false)

static void test_readback_upload_buffer()
{
	static const uint32_t dummy[] = { 10, 20, 30, 40 };
	auto upload = device.create_upload_buffer(sizeof(dummy), dummy);
	bool done = false;

	device.async_readback(
		upload.get(), 0, [&](const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)
		{
			done = true;
			ASSERT_THAT(footprint.Offset == 0);
			ASSERT_THAT(footprint.Footprint.Width == sizeof(dummy));
			ASSERT_THAT(footprint.Footprint.Height == 1);
			ASSERT_THAT(footprint.Footprint.Depth == 1);
			ASSERT_THAT(footprint.Footprint.Format == DXGI_FORMAT_UNKNOWN);
			ASSERT_THAT(footprint.Footprint.RowPitch == sizeof(dummy));
			ASSERT_THAT(memcmp(data, dummy, sizeof(dummy)) == 0);
		});

	device.wait_idle();
	device.next_frame_context();
	ASSERT_THAT(done);
}

static void test_readback_default_buffer()
{
	static const uint32_t dummy[] = { 10, 20, 30, 40 };
	auto upload = device.create_default_buffer(sizeof(dummy), dummy,
	                                           D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_COPY_SOURCE);
	bool done = false;

	device.async_readback(
		upload.get(), 0, [&](const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)
		{
			done = true;
			ASSERT_THAT(footprint.Offset == 0);
			ASSERT_THAT(footprint.Footprint.Width == sizeof(dummy));
			ASSERT_THAT(footprint.Footprint.Height == 1);
			ASSERT_THAT(footprint.Footprint.Depth == 1);
			ASSERT_THAT(footprint.Footprint.Format == DXGI_FORMAT_UNKNOWN);
			ASSERT_THAT(footprint.Footprint.RowPitch == sizeof(dummy));
			ASSERT_THAT(memcmp(data, dummy, sizeof(dummy)) == 0);
		});

	device.wait_idle();
	device.next_frame_context();
	ASSERT_THAT(done);
}

static void test_readback_upload_texture()
{
	static const uint32_t dummy[] = { 10, 20, 30, 40, 50, 60 };
	InitialTextureData init = { dummy, 3 * sizeof(uint32_t), sizeof(dummy) };
	auto upload = device.create_texture2d(DXGI_FORMAT_R32_UINT, 3, 2, 1, 1,
		D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_COPY_SOURCE, &init);
	bool done = false;

	device.async_readback(
		upload.get(), 0, [&](const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)
		{
			done = true;
			ASSERT_THAT(footprint.Offset == 0);
			ASSERT_THAT(footprint.Footprint.Width == 3);
			ASSERT_THAT(footprint.Footprint.Height == 2);
			ASSERT_THAT(footprint.Footprint.Depth == 1);
			ASSERT_THAT(footprint.Footprint.Format == DXGI_FORMAT_R32_UINT);
			for (uint32_t y = 0; y < 2; y++)
				ASSERT_THAT(memcmp(data + footprint.Footprint.RowPitch * y, dummy + 3 * y, init.row_pitch) == 0);
		});

	device.wait_idle();
	device.next_frame_context();
	ASSERT_THAT(done);
}

static void test_basic_uav_readback()
{
	static const uint32_t dummy[] = { 10, 20, 30, 40, 50, 60 };
	InitialTextureData init = { dummy, 3 * sizeof(uint32_t), sizeof(dummy) };
	auto upload = device.create_texture2d(DXGI_FORMAT_R32_UINT, 3, 2, 1, 1,
		D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_COPY_SOURCE, &init);
	auto uav = device.create_texture2d(DXGI_FORMAT_R32_UINT, 3, 2, 1, 1,
		D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_UNORDERED_ACCESS, nullptr);
	bool done = false;

	device.create_srv(0, upload.get(), nullptr);
	device.create_uav(1, uav.get(), nullptr);

	auto &pso = shaders.basic_copy_srv_uav_2d;

	device.begin_renderdoc_capture();

	device.begin_work();
	device.setup_compute(pso);
	device.set_resource_table(0, 0);
	device.dispatch(1, 1, 1);
	device.transition_resource(uav.get(), D3D12_RESOURCE_STATE_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_COPY_SOURCE);
	device.end_work([](uint64_t ticks) { ASSERT_THAT(ticks != 0); });

	device.async_readback(
		uav.get(), 0, [&](const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)
		{
			done = true;
			ASSERT_THAT(footprint.Offset == 0);
			ASSERT_THAT(footprint.Footprint.Width == 3);
			ASSERT_THAT(footprint.Footprint.Height == 2);
			ASSERT_THAT(footprint.Footprint.Depth == 1);
			ASSERT_THAT(footprint.Footprint.Format == DXGI_FORMAT_R32_UINT);
			for (uint32_t y = 0; y < 2; y++)
				ASSERT_THAT(memcmp(data + footprint.Footprint.RowPitch * y, dummy + 3 * y, init.row_pitch) == 0);
		});

	device.wait_idle();
	device.next_frame_context();
	ASSERT_THAT(done);

	device.end_renderdoc_capture();
}

static void test_basic_sampler()
{
	static const float dummy[] = { 10, 20, 30, 40, 50, 60 };
	InitialTextureData init = { dummy, 3 * sizeof(float), sizeof(dummy) };
	auto upload = device.create_texture2d(DXGI_FORMAT_R32_FLOAT, 3, 2, 1, 1,
		D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_COPY_SOURCE, &init);
	auto uav = device.create_texture2d(DXGI_FORMAT_R32G32_FLOAT, 8, 8, 1, 1,
		D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_UNORDERED_ACCESS, nullptr);
	bool done = false;

	device.create_srv(0, upload.get(), nullptr);
	device.create_uav(1, uav.get(), nullptr);

	D3D12_SAMPLER_DESC border_samp = {};
	border_samp.BorderColor[0] = 4.0f;
	border_samp.AddressU = D3D12_TEXTURE_ADDRESS_MODE_BORDER;
	border_samp.AddressV = D3D12_TEXTURE_ADDRESS_MODE_BORDER;
	border_samp.AddressW = D3D12_TEXTURE_ADDRESS_MODE_BORDER;
	device.create_sampler(0, &border_samp);

	border_samp.AddressU = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	border_samp.AddressV = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	border_samp.AddressW = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	device.create_sampler(1, &border_samp);

	auto &pso = shaders.basic_sampled_texture;

	device.begin_renderdoc_capture();

	device.begin_work();
	{
		device.setup_compute(pso);
		device.set_resource_table(0, 0);
		device.set_sampler_table(1, 0);
		device.dispatch(1, 1, 1);
		device.transition_resource(uav.get(), D3D12_RESOURCE_STATE_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_COPY_SOURCE);
	}
	device.end_work([](uint64_t ticks) { ASSERT_THAT(ticks != 0); });

	device.async_readback(
		uav.get(), 0, [&](const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &footprint)
		{
			auto *fp_data = reinterpret_cast<const float *>(data);
			done = true;
			ASSERT_THAT(footprint.Offset == 0);
			ASSERT_THAT(footprint.Footprint.Width == 8);
			ASSERT_THAT(footprint.Footprint.Height == 8);
			ASSERT_THAT(footprint.Footprint.Depth == 1);
			ASSERT_THAT(footprint.Footprint.Format == DXGI_FORMAT_R32G32_FLOAT);
			for (uint32_t y = 0; y < 8; y++)
			{
				for (uint32_t x = 0; x < 8; x++)
				{
					auto linear_pixel = y * footprint.Footprint.RowPitch / sizeof(float) + 2 * x;
					ASSERT_THAT(fp_data[linear_pixel + 0] == 4.0f);
					ASSERT_THAT(fp_data[linear_pixel + 1] == 60.0f);
				}
			}
		});

	device.wait_idle();
	device.next_frame_context();
	ASSERT_THAT(done);

	device.end_renderdoc_capture();
}

static void test_root_desc()
{
	uint32_t buf[64];
	for (int i = 0; i < 64; i++)
		buf[i] = i + 1;

	auto upload = device.create_upload_buffer(sizeof(buf), buf);
	auto uav = device.create_default_buffer(sizeof(buf), nullptr,
	                                        D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS,
	                                        D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
	bool done = false;
	auto &pso = shaders.copy_root_desc;

	device.begin_renderdoc_capture();

	device.begin_work();
	{
		device.setup_compute(pso);
		device.set_root_srv(0, upload->GetGPUVirtualAddress());
		device.set_root_uav(1, uav->GetGPUVirtualAddress());
		device.set_root_cbv(2, upload->GetGPUVirtualAddress());
		static const uint32_t consts[] = { 100, 200, 300, 400 };
		device.set_constants(3, buf, 4);
		device.dispatch(1, 1, 1);
		device.uav_barrier();
		device.set_constants(3, consts, 4);
		device.dispatch(1, 1, 1);
		device.transition_resource(uav.get(), D3D12_RESOURCE_STATE_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_COPY_SOURCE);
	}
	device.end_work([](uint64_t ticks) { ASSERT_THAT(ticks != 0); });

	device.async_readback(
		uav.get(), 0, [&](const uint8_t *data, const D3D12_PLACED_SUBRESOURCE_FOOTPRINT &)
		{
			auto *uint_data = reinterpret_cast<const uint32_t *>(data);
			done = true;
			for (uint32_t i = 0; i < 64; i++)
				ASSERT_THAT(uint_data[i] == i + 2 + 100 * ((i & 3) + 1));
		});

	device.wait_idle();
	device.next_frame_context();
	ASSERT_THAT(done);

	device.end_renderdoc_capture();
}

static void run_self_tests()
{
	test_readback_upload_buffer();
	test_readback_default_buffer();
	test_readback_upload_texture();
	test_basic_uav_readback();
	test_basic_sampler();
	test_root_desc();
}

static bool filter_test(const std::string &test)
{
	for (auto &r : options.filter_negatives)
		if (std::regex_search(test, r))
			return false;

	if (!options.filter_ands.empty())
	{
		for (auto &r: options.filter_ands)
			if (!std::regex_search(test, r))
				return false;
	}

	if (!options.filter_ors.empty())
	{
		for (auto &r: options.filter_ors)
			if (std::regex_search(test, r))
				return true;

		return false;
	}

	return true;
}

static void run_timed_benchmark(const std::string &test, const std::function<uint64_t ()> work_cb)
{
	if (!filter_test(test))
	{
		LOGI("Skipped %s.\n", test.c_str());
		return;
	}

	LOGI("Running %s ...\n", test.c_str());
	std::vector<double> durations;
	durations.reserve(options.max_iterations);

	if (options.renderdoc)
	{
		device.wait_idle();
		device.begin_renderdoc_capture();
		auto *list = device.begin_work();
		constexpr UINT PIX_EVENT_ANSI_VERSION = 1;
		list->BeginEvent(PIX_EVENT_ANSI_VERSION, test.c_str(), test.size());
		(void)work_cb();
		list->EndEvent();
		device.end_work({});
		device.wait_idle();
		device.end_renderdoc_capture();
		return;
	}

	// Warm-up for GPU to make sure it's running at decent power state.
	constexpr uint32_t WarmupIterations = 4;
	for (uint32_t iter = 0; iter < WarmupIterations; iter++)
	{
		device.begin_work();
		(void)work_cb();
		device.end_work({});
		device.next_frame_context();
		if (options.verbose)
			LOGI("Running %s warm-up iteration %u / %u\n", test.c_str(), iter, WarmupIterations);
	}

	auto base_ts = std::chrono::steady_clock::now();

	for (uint32_t iter = 0; iter < options.max_iterations; iter++)
	{
		if (iter >= options.min_iterations)
		{
			auto now_ts = std::chrono::steady_clock::now();
			auto diff = now_ts - base_ts;
			auto diff_seconds = double(std::chrono::duration_cast<std::chrono::milliseconds>(diff).count()) * 1e-3;
			if (diff_seconds > options.max_seconds_per_run)
			{
				if (options.verbose)
					LOGI("Timing out test early due to reaching maximum time.\n");
				break;
			}
		}

		device.begin_work();
		auto work_number = work_cb();
		device.end_work([&durations, work_number](uint64_t ticks) { durations.push_back(double(ticks) * 1e-9 / double(work_number)); });
		device.next_frame_context();
		if (options.verbose)
			LOGI("Running %s iteration %u / %u\n", test.c_str(), iter, options.max_iterations);
	}

	device.wait_idle();

	if (durations.empty())
	{
		LOGE("There are no timestamps ...\n");
		return;
	}

	std::sort(durations.begin(), durations.end());

	double sum = 0.0;
	double squared_sum = 0.0;
	for (auto d : durations)
	{
		sum += d;
		squared_sum += d * d;
	}

	auto avg = sum / double(durations.size());
	double median = durations[durations.size() / 2];
	double variance = std::max(0.0, (squared_sum / double(durations.size())) - avg * avg);
	results.add_result(test, median, avg, 100.0 * std::sqrt(variance) / avg);
	LOGI("  ... completed %s\n", test.c_str());
}

static void run_srv_2d_tests()
{
	const uint32_t blank = 1;
	InitialTextureData init = { &blank, 4, 4 };
	auto srv = device.create_texture2d(DXGI_FORMAT_R32_UINT, 1, 1, 1024, 1,
	                                   D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, &init);

	for (int i = 0; i < 1024; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.Format = DXGI_FORMAT_R32_UINT;
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2DARRAY;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Texture2DArray.MipLevels = 1;
		srv_desc.Texture2DArray.FirstArraySlice = i;
		srv_desc.Texture2DArray.ArraySize = 1;
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 1024; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	const struct
	{
		PipelineState &state;
		uint32_t groups_y;
	} states[] = {
		{ shaders.srv_2d_bindless_coherent_throughput, 1024 },
		{ shaders.srv_2d_bindless_coherent_throughput_low_occupancy, 64 },
		{ shaders.srv_2d_bindless_coherent_latency, 256 },
		{ shaders.srv_2d_bindless_coherent_latency_low_occupancy, 32 },
		{ shaders.srv_2d_bindless_divergent_throughput, 256 },
		{ shaders.srv_2d_bindless_divergent_throughput_low_occupancy, 16 },
		{ shaders.srv_2d_bindless_divergent_latency, 64 },
		{ shaders.srv_2d_bindless_divergent_latency_low_occupancy, 8 },
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state.state.name, [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.dispatch(512, state.groups_y, 1);
			return 512 * state.groups_y;
		});
	}

	for (auto &state : states)
	{
		run_timed_benchmark(std::string(state.state.name) + ".single", [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			for (uint32_t i = 0; i < state.groups_y; i++)
			{
				device.dispatch(1, 1, 1);
				device.uav_barrier();
			}
			return state.groups_y;
		});
	}

	device.wait_idle();
}

static void run_uav_2d_tests()
{
	const uint32_t blank = 1;
	InitialTextureData init = { &blank, 4, 4 };
	auto srv = device.create_texture2d(DXGI_FORMAT_R32_UINT, 1, 1, 1024, 1,
		D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_UNORDERED_ACCESS, &init);

	for (int i = 0; i < 1024; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
		uav_desc.Texture2DArray.FirstArraySlice = i;
		uav_desc.Texture2DArray.ArraySize = 1;
		device.create_uav(i, srv.get(), &uav_desc);
	}

	for (int i = 0; i < 1024; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	const struct
	{
		PipelineState &state;
		uint32_t groups_y;
	} states[] = {
		{ shaders.uav_2d_bindless_coherent_throughput, 1024 },
		{ shaders.uav_2d_bindless_coherent_throughput_low_occupancy, 64 },
		{ shaders.uav_2d_bindless_coherent_latency, 256 },
		{ shaders.uav_2d_bindless_coherent_latency_low_occupancy, 32 },
		{ shaders.uav_2d_bindless_divergent_throughput, 256 },
		{ shaders.uav_2d_bindless_divergent_throughput_low_occupancy, 16 },
		{ shaders.uav_2d_bindless_divergent_latency, 64 },
		{ shaders.uav_2d_bindless_divergent_latency_low_occupancy, 8 },
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state.state.name, [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.dispatch(512, state.groups_y, 1);
			return 512 * state.groups_y;
		});
	}

	for (auto &state : states)
	{
		run_timed_benchmark(std::string(state.state.name) + ".single", [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			for (uint32_t i = 0; i < state.groups_y; i++)
			{
				device.dispatch(1, 1, 1);
				device.uav_barrier();
			}
			return state.groups_y;
		});
	}

	device.wait_idle();
}

static void run_uav_write_2d_tests()
{
	const uint32_t blank = 1;
	InitialTextureData init = { &blank, 4, 4 };
	auto uav = device.create_texture2d(DXGI_FORMAT_R32_UINT, 1, 1, 1024, 1,
	                                   D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_UNORDERED_ACCESS, &init);
	auto uav_buffer = device.create_default_buffer(64 * 1024 * 1024, nullptr,
		D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);

	constexpr int NumDescPerBlock = 4096;

	for (int i = 0; i < NumDescPerBlock; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
		uav_desc.Texture2DArray.ArraySize = 1;
		uav_desc.Texture2DArray.FirstArraySlice = i & 1023;
		device.create_uav(0 * NumDescPerBlock + i, uav.get(), &uav_desc);

		uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = i;
		uav_desc.Buffer.NumElements = 1024 * 1024;

		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		device.create_uav(1 * NumDescPerBlock + i, uav_buffer.get(), &uav_desc);
		uav_desc.Format = DXGI_FORMAT_R32G32_UINT;
		device.create_uav(2 * NumDescPerBlock + i, uav_buffer.get(), &uav_desc);
		uav_desc.Format = DXGI_FORMAT_R32G32B32A32_UINT; // For whatever reason RGB32_UINT is not supported?
		device.create_uav(3 * NumDescPerBlock + i, uav_buffer.get(), &uav_desc);
		uav_desc.Format = DXGI_FORMAT_R32G32B32A32_UINT;
		device.create_uav(4 * NumDescPerBlock + i, uav_buffer.get(), &uav_desc);
	}

	const struct
	{
		PipelineState &state;
		uint32_t groups_y;
		uint32_t desc_block;
	} states[] = {
		{shaders.uav_write_2d_bindless_coherent, 1024, 0},
		{shaders.uav_write_2d_bindless_divergent, 64, 0},
		{shaders.uav_write_uint1_bindless_coherent, 1024, 1},
		{shaders.uav_write_uint1_bindless_divergent, 64, 1},
		{shaders.uav_write_uint2_bindless_coherent, 1024, 2},
		{shaders.uav_write_uint2_bindless_divergent, 64, 2},
		{shaders.uav_write_uint3_bindless_coherent, 1024, 3},
		{shaders.uav_write_uint3_bindless_divergent, 64, 3},
		{shaders.uav_write_uint4_bindless_coherent, 1024, 4},
		{shaders.uav_write_uint4_bindless_divergent, 64, 4},
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state.state.name, [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, NumDescPerBlock * state.desc_block);
			device.dispatch(512, state.groups_y, 1);
			device.uav_barrier();
			return 512 * state.groups_y;
		});
	}

	device.wait_idle();
}

static void run_srv_texel_buffer_tests()
{
	auto srv = device.create_default_buffer(64 * 1024 * 1024, nullptr,
	                                        D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);

	for (int i = 0; i < 1024; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.Format = DXGI_FORMAT_R32_UINT;
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Buffer.FirstElement = i;
		srv_desc.Buffer.NumElements = 1024 * 1024;
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 1024; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = i;
		uav_desc.Buffer.NumElements = 1024 * 1024;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	const struct
	{
		PipelineState &state;
		uint32_t groups_y;
	} states[] = {
		{ shaders.srv_texel_buf_bindless_coherent_throughput, 1024 },
		{ shaders.srv_texel_buf_bindless_coherent_throughput_low_occupancy, 64 },
		{ shaders.srv_texel_buf_bindless_coherent_latency, 256 },
		{ shaders.srv_texel_buf_bindless_coherent_latency_low_occupancy, 32 },
		{ shaders.srv_texel_buf_bindless_divergent_throughput, 256 },
		{ shaders.srv_texel_buf_bindless_divergent_throughput_low_occupancy, 16 },
		{ shaders.srv_texel_buf_bindless_divergent_latency, 64 },
		{ shaders.srv_texel_buf_bindless_divergent_latency_low_occupancy, 8 },
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state.state.name, [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.dispatch(512, state.groups_y, 1);
			return 512 * state.groups_y;
		});
	}

	for (auto &state : states)
	{
		run_timed_benchmark(std::string(state.state.name) + ".single", [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			for (uint32_t i = 0; i < state.groups_y; i++)
			{
				device.dispatch(1, 1, 1);
				device.uav_barrier();
			}
			return state.groups_y;
		});
	}

	device.wait_idle();
}

static void run_srv_strided_tests()
{
	auto srv = device.create_default_buffer(64 * 1024 * 1024, nullptr,
		D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);

	D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
	srv_desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
	srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
	srv_desc.Buffer.FirstElement = 0;
	srv_desc.Buffer.NumElements = 256 * 1024;

	static const DXGI_FORMAT texel_formats[] = {
		DXGI_FORMAT_R32_FLOAT,
		DXGI_FORMAT_R32G32_FLOAT,
		DXGI_FORMAT_R32G32B32_FLOAT,
		DXGI_FORMAT_R32G32B32A32_FLOAT
	};

	for (int i = 0; i < 4; i++)
	{
		srv_desc.Format = texel_formats[i];
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 4; i++)
	{
		srv_desc.Format = DXGI_FORMAT_UNKNOWN;
		srv_desc.Buffer.StructureByteStride = 4 * (i + 1);
		device.create_srv(4 + i, srv.get(), &srv_desc);
	}

	srv_desc.Format = DXGI_FORMAT_R32_TYPELESS;
	srv_desc.Buffer.Flags = D3D12_BUFFER_SRV_FLAG_RAW;
	srv_desc.Buffer.StructureByteStride = 0;
	device.create_srv(8, srv.get(), &srv_desc);

	D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
	uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
	uav_desc.Buffer.FirstElement = 0;
	uav_desc.Buffer.NumElements = 4096;
	uav_desc.Buffer.StructureByteStride = 16;
	device.create_uav(1024, nullptr, &uav_desc);

	const struct
	{
		PipelineState &state;
		uint32_t thread_stride;
		uint32_t loop_stride;
		uint32_t heap_index;
	} states[] = {
		{ shaders.srv_texel_buf_strided_uint1, 1, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 2, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 3, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 4, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 5, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 6, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 7, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1, 8, 32, 0 },

		{ shaders.srv_texel_buf_strided_uint2, 1, 32, 1 },
		{ shaders.srv_texel_buf_strided_uint2, 2, 32, 1 },
		{ shaders.srv_texel_buf_strided_uint2, 3, 32, 1 },
		{ shaders.srv_texel_buf_strided_uint2, 4, 32, 1 },

		{ shaders.srv_texel_buf_strided_uint3, 1, 32, 2 },
		{ shaders.srv_texel_buf_strided_uint3, 2, 32, 2 },

		{ shaders.srv_texel_buf_strided_uint4, 1, 32, 3 },
		{ shaders.srv_texel_buf_strided_uint4, 2, 32, 3 },

		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 1, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 2, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 3, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 4, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 5, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 6, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 7, 32, 0 },
		{ shaders.srv_texel_buf_strided_uint1_const_iter_stride, 8, 32, 0 },

		{ shaders.srv_texel_buf_strided_uint2_const_iter_stride, 1, 32, 1 },
		{ shaders.srv_texel_buf_strided_uint2_const_iter_stride, 2, 32, 1 },
		{ shaders.srv_texel_buf_strided_uint2_const_iter_stride, 3, 32, 1 },
		{ shaders.srv_texel_buf_strided_uint2_const_iter_stride, 4, 32, 1 },

		{ shaders.srv_texel_buf_strided_uint3_const_iter_stride, 1, 32, 2 },
		{ shaders.srv_texel_buf_strided_uint3_const_iter_stride, 2, 32, 2 },

		{ shaders.srv_texel_buf_strided_uint4_const_iter_stride, 1, 32, 3 },
		{ shaders.srv_texel_buf_strided_uint4_const_iter_stride, 2, 32, 3 },

		{ shaders.srv_structured_strided_uint1, 1, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 2, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 3, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 4, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 5, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 6, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 7, 32, 4 },
		{ shaders.srv_structured_strided_uint1, 8, 32, 4 },

		{ shaders.srv_structured_strided_uint2, 1, 32, 5 },
		{ shaders.srv_structured_strided_uint2, 2, 32, 5 },
		{ shaders.srv_structured_strided_uint2, 3, 32, 5 },
		{ shaders.srv_structured_strided_uint2, 4, 32, 5 },

		{ shaders.srv_structured_strided_uint3, 1, 32, 6 },
		{ shaders.srv_structured_strided_uint3, 2, 32, 6 },

		{ shaders.srv_structured_strided_uint4, 1, 32, 7 },
		{ shaders.srv_structured_strided_uint4, 2, 32, 7 },

		{ shaders.srv_bab_strided_unaligned_uint1, 4, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 8, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 12, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 16, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 20, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 24, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 28, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint1, 32, 128, 8 },

		{ shaders.srv_bab_strided_unaligned_uint2, 8, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint2, 16, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint2, 24, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint2, 32, 128, 8 },

		{ shaders.srv_bab_strided_unaligned_uint3, 12, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint3, 24, 128, 8 },

		{ shaders.srv_bab_strided_unaligned_uint4, 16, 128, 8 },
		{ shaders.srv_bab_strided_unaligned_uint4, 32, 128, 8 },

		{ shaders.srv_bab_strided_aligned_uint1, 1, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 2, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 3, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 4, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 5, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 6, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 7, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint1, 8, 32, 8 },

		{ shaders.srv_bab_strided_aligned_uint2, 1, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint2, 2, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint2, 3, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint2, 4, 32, 8 },

		{ shaders.srv_bab_strided_aligned_uint3, 1, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint3, 2, 32, 8 },

		{ shaders.srv_bab_strided_aligned_uint4, 1, 32, 8 },
		{ shaders.srv_bab_strided_aligned_uint4, 2, 32, 8 },
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state.state.name + ("_" + std::to_string(state.thread_stride)), [&]() -> uint64_t
		{
			device.setup_compute(state.state);
			device.set_resource_table(0, state.heap_index);
			device.set_resource_table(1, 1024);
			device.set_constant(2, 0, state.thread_stride);
			device.set_constant(2, 1, state.loop_stride);
			device.set_constant(2, 2, 64);
			device.set_constant(2, 0, 0);
			device.set_constant(2, 1, 0);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}

static void run_srv_struct_buffer_tests()
{
	auto srv = device.create_default_buffer(64 * 1024 * 1024, nullptr,
	                                        D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);

	for (int i = 0; i < 8; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Buffer.FirstElement = i;
		srv_desc.Buffer.NumElements = 256 * 1024;
		srv_desc.Buffer.StructureByteStride = (i + 1) * 4;
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 4096; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = 0;
		uav_desc.Buffer.NumElements = 4096;
		uav_desc.Buffer.StructureByteStride = 16;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	PipelineState *states[] =
	{
#define srv_group(name) \
		&shaders.srv_structured_buffer_##name##_uint1, \
		&shaders.srv_structured_buffer_##name##_uint2, \
		&shaders.srv_structured_buffer_##name##_uint3, \
		&shaders.srv_structured_buffer_##name##_uint4, \
		&shaders.srv_structured_buffer_##name##_uint5, \
		&shaders.srv_structured_buffer_##name##_uint6, \
		&shaders.srv_structured_buffer_##name##_uint7, \
		&shaders.srv_structured_buffer_##name##_uint8
		srv_group(vmem), srv_group(mixed), srv_group(bindless_vmem),
#undef srv_group
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state->name, [&]() -> uint64_t
		{
			device.setup_compute(*state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.set_constant(2, 0, 0);
			device.set_constant(2, 1, 0);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}

static void run_srv_bab_tests()
{
	auto srv = device.create_default_buffer(64 * 1024 * 1024, nullptr,
		D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);

	for (int i = 0; i < 8; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
		srv_desc.Buffer.Flags = D3D12_BUFFER_SRV_FLAG_RAW;
		srv_desc.Format = DXGI_FORMAT_R32_TYPELESS;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Buffer.FirstElement = i * 4;
		srv_desc.Buffer.NumElements = 256 * 1024;
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 4096; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = 0;
		uav_desc.Buffer.NumElements = 4096;
		uav_desc.Format = DXGI_FORMAT_R32_TYPELESS;
		uav_desc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	PipelineState *states[] =
	{
#define srv_group(name) \
		&shaders.srv_bab_##name##_uint1, \
		&shaders.srv_bab_##name##_uint2, \
		&shaders.srv_bab_##name##_uint3, \
		&shaders.srv_bab_##name##_uint4, \
		&shaders.srv_bab_##name##_uint5, \
		&shaders.srv_bab_##name##_uint6, \
		&shaders.srv_bab_##name##_uint7, \
		&shaders.srv_bab_##name##_uint8
		srv_group(vmem), srv_group(mixed), srv_group(unaligned),
#undef srv_group
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state->name, [&]() -> uint64_t
		{
			device.setup_compute(*state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.set_constant(2, 0, 0);
			device.set_constant(2, 1, 0);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}

static void run_srv_bab_tests_16bit()
{
	if (!device.supports_native_16bit())
		return;

	auto srv = device.create_default_buffer(64 * 1024 * 1024, nullptr,
		D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);

	for (int i = 0; i < 8; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
		srv_desc.Buffer.Flags = D3D12_BUFFER_SRV_FLAG_RAW;
		srv_desc.Format = DXGI_FORMAT_R32_TYPELESS;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Buffer.FirstElement = i * 4;
		srv_desc.Buffer.NumElements = 256 * 1024;
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 4096; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = 0;
		uav_desc.Buffer.NumElements = 4096;
		uav_desc.Format = DXGI_FORMAT_R32_TYPELESS;
		uav_desc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	PipelineState *states[] =
	{
#define srv_group(name) \
		&shaders.srv_bab_##name##_uint16_1, \
		&shaders.srv_bab_##name##_uint16_2, \
		&shaders.srv_bab_##name##_uint16_3, \
		&shaders.srv_bab_##name##_uint16_4, \
		&shaders.srv_bab_##name##_uint16_5, \
		&shaders.srv_bab_##name##_uint16_6, \
		&shaders.srv_bab_##name##_uint16_7, \
		&shaders.srv_bab_##name##_uint16_8
		srv_group(vmem), srv_group(mixed), srv_group(unaligned),
#undef srv_group
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state->name, [&]() -> uint64_t
		{
			device.setup_compute(*state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.set_constant(2, 0, 0);
			device.set_constant(2, 1, 0);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}

static void run_uav_bab_read_tests()
{
	auto uav = device.create_default_buffer(64 * 1024 * 1024, nullptr,
		D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);

	for (int i = 0; i < 8; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
		uav_desc.Format = DXGI_FORMAT_R32_TYPELESS;
		uav_desc.Buffer.FirstElement = i * 4;
		uav_desc.Buffer.NumElements = 256 * 1024;
		device.create_uav(i, uav.get(), &uav_desc);
	}

	for (int i = 0; i < 4096; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = 0;
		uav_desc.Buffer.NumElements = 4096;
		uav_desc.Format = DXGI_FORMAT_R32_TYPELESS;
		uav_desc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	PipelineState *states[] =
	{
#define uav_group(name) \
		&shaders.uav_bab_read_##name##_uint1, \
		&shaders.uav_bab_read_##name##_uint2, \
		&shaders.uav_bab_read_##name##_uint3, \
		&shaders.uav_bab_read_##name##_uint4, \
		&shaders.uav_bab_read_##name##_uint5, \
		&shaders.uav_bab_read_##name##_uint6, \
		&shaders.uav_bab_read_##name##_uint7, \
		&shaders.uav_bab_read_##name##_uint8
		uav_group(vmem), uav_group(mixed), uav_group(unaligned),
#undef uav_group
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state->name, [&]() -> uint64_t
		{
			device.setup_compute(*state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.set_constant(2, 0, 0);
			device.set_constant(2, 1, 0);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}


static void run_uav_struct_buffer_tests()
{
	auto uav = device.create_default_buffer(1024 * 1024, nullptr,
											D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS,
											D3D12_RESOURCE_STATE_UNORDERED_ACCESS);

	for (int i = 0; i < 8; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = i;
		uav_desc.Buffer.NumElements = 256 * 32;
		uav_desc.Buffer.StructureByteStride = (i + 1) * 4;
		device.create_uav(i, uav.get(), &uav_desc);
	}

	PipelineState *states[] =
	{
#define uav_group(name) \
	&shaders.uav_structured_buffer##name##uint1, \
	&shaders.uav_structured_buffer##name##uint2, \
	&shaders.uav_structured_buffer##name##uint3, \
	&shaders.uav_structured_buffer##name##uint4, \
	&shaders.uav_structured_buffer##name##uint5, \
	&shaders.uav_structured_buffer##name##uint6, \
	&shaders.uav_structured_buffer##name##uint7, \
	&shaders.uav_structured_buffer##name##uint8
		uav_group(_), uav_group(_bindless_), uav_group(_bindless_loop_),
#undef uav_group
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state->name, [&]() -> uint64_t
		{
			device.setup_compute(*state);
			device.set_resource_table(0, 0);
			device.set_constant(1, 0, 0);
			device.set_constant(1, 1, 0);
			device.set_constant(1, 2, 64);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}

static void run_srv_struct_buffer_tests_16bit()
{
	if (!device.supports_native_16bit())
		return;

	auto srv = device.create_default_buffer(1024 * 1024, nullptr,
											D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);

	for (int i = 0; i < 8; i++)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
		srv_desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
		srv_desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srv_desc.Buffer.FirstElement = i;
		srv_desc.Buffer.NumElements = 256 * 32;
		srv_desc.Buffer.StructureByteStride = (i + 1) * 2;
		device.create_srv(i, srv.get(), &srv_desc);
	}

	for (int i = 0; i < 4096; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
		uav_desc.Buffer.FirstElement = 0;
		uav_desc.Buffer.NumElements = 4096;
		uav_desc.Buffer.StructureByteStride = 16;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	PipelineState *states[] =
	{
#define srv_group(name) \
	&shaders.srv_structured_buffer_uint16_##name##_uint1, \
	&shaders.srv_structured_buffer_uint16_##name##_uint2, \
	&shaders.srv_structured_buffer_uint16_##name##_uint3, \
	&shaders.srv_structured_buffer_uint16_##name##_uint4, \
	&shaders.srv_structured_buffer_uint16_##name##_uint5, \
	&shaders.srv_structured_buffer_uint16_##name##_uint6, \
	&shaders.srv_structured_buffer_uint16_##name##_uint7, \
	&shaders.srv_structured_buffer_uint16_##name##_uint8
		srv_group(vmem), srv_group(mixed), srv_group(bindless_vmem),
#undef srv_group
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state->name, [&]() -> uint64_t
		{
			device.setup_compute(*state);
			device.set_resource_table(0, 0);
			device.set_resource_table(1, 1024);
			device.set_constant(2, 0, 0);
			device.set_constant(2, 1, 0);
			device.dispatch(64, 4096, 1);
			return 64 * 4096;
		});
	}

	device.wait_idle();
}

static void run_cbv_tests()
{
	auto cbv = device.create_default_buffer(1024 * 1024, nullptr,
	                                        D3D12_RESOURCE_FLAG_NONE, D3D12_RESOURCE_STATE_GENERIC_READ);

	for (int i = 0; i < 1024; i++)
		device.create_cbv(i, cbv->GetGPUVirtualAddress() + 256 * i, 256);

	for (int i = 0; i < 1024; i++)
	{
		D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc = {};
		uav_desc.Format = DXGI_FORMAT_R32_UINT;
		uav_desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
		device.create_uav(i + 1024, nullptr, &uav_desc);
	}

	const struct
	{
		PipelineState &state;
		uint32_t groups_y;
		uint32_t num_constants;
		bool root_desc;
		bool root_table;
		uint32_t extra_root_desc;
	} states[] = {
		{shaders.cbv_root_constants_8_read, 1024, 8, false, false},
		{shaders.cbv_root_constants_16_read, 1024, 16, false, false},
		{shaders.cbv_root_constants_32_read, 1024, 32, false, false},
		{shaders.cbv_root_constants_60_read, 1024, 60, false, false},
		{shaders.cbv_root_desc_read_coherent, 512, 0, true, false},
		{shaders.cbv_root_desc_read_divergent, 512, 0, true, false},
		{shaders.cbv_root_table_read_coherent, 256, 0, false, true},
		{shaders.cbv_root_table_read_divergent, 256, 0, false, true},
		{shaders.cbv_root_table_bindless_coherent, 128, 0, false, true},
		{shaders.cbv_root_table_bindless_divergent, 128, 0, false, true},
		{shaders.cbv_root_desc_4_read_coherent, 1024, 0, true, false, 3},
		{shaders.cbv_root_desc_8_read_coherent, 1024, 0, true, false, 7},
		{shaders.cbv_root_desc_12_read_coherent, 1024, 0, true, false, 11},
		{shaders.cbv_root_desc_4_read_divergent, 1024, 0, true, false, 3},
		{shaders.cbv_root_desc_8_read_divergent, 1024, 0, true, false, 7},
		{shaders.cbv_root_desc_12_read_divergent, 1024, 0, true, false, 11},
	};

	for (auto &state : states)
	{
		run_timed_benchmark(state.state.name, [&]() -> uint64_t
		{
			static uint32_t dummy[64];

			device.setup_compute(state.state);

			if (state.num_constants)
				device.set_constants(0, dummy, state.num_constants);
			else if (state.root_desc)
				device.set_root_cbv(0, cbv->GetGPUVirtualAddress());
			else if (state.root_table)
				device.set_resource_table(0, 0);

			device.set_resource_table(1, 1024);

			for (uint32_t i = 0; i < state.extra_root_desc; i++)
				device.set_root_cbv(2 + i, cbv->GetGPUVirtualAddress() + 256 * (i + 1));

			device.dispatch(512, state.groups_y, 1);
			return 512 * state.groups_y;
		});
	}
}

static void run_benchmarks()
{
	device.clear_resource_heap();
	run_srv_2d_tests();

	device.clear_resource_heap();
	run_uav_2d_tests();

	device.clear_resource_heap();
	run_uav_write_2d_tests();

	device.clear_resource_heap();
	run_srv_texel_buffer_tests();

	device.clear_resource_heap();
	run_srv_struct_buffer_tests();

	device.clear_resource_heap();
	run_srv_strided_tests();

	device.clear_resource_heap();
	run_srv_bab_tests();

	device.clear_resource_heap();
	run_srv_bab_tests_16bit();

	device.clear_resource_heap();
	run_uav_bab_read_tests();

	device.clear_resource_heap();
	run_uav_struct_buffer_tests();

	device.clear_resource_heap();
	run_srv_struct_buffer_tests_16bit();

	device.clear_resource_heap();
	run_cbv_tests();
}

int main(int argc, char **argv)
{
	std::string d3d12;
	std::string output;
	bool validate = false;
	bool vkd3d_proton = false;
	std::string batch;
	Util::CLICallbacks cbs;
	bool self_test = false;

	cbs.add("--d3d12", [&](Util::CLIParser &parser) { d3d12 = parser.next_string(); });
	cbs.add("--vkd3d-proton", [&](Util::CLIParser &) { vkd3d_proton = true; });
	cbs.add("--validate", [&](Util::CLIParser &) { validate = true; });
	cbs.add("--verbose", [&](Util::CLIParser &) { options.verbose = true; });
	cbs.add("--output", [&](Util::CLIParser &parser) { output = parser.next_string(); });
	cbs.add("--self-test", [&](Util::CLIParser &) { self_test = true; });
	cbs.add("--renderdoc", [&](Util::CLIParser &) { options.renderdoc = true; });
	cbs.add("--filter", [&](Util::CLIParser &parser)
	{
		options.filter_ors.emplace_back(parser.next_string());
	});
	cbs.add("--filter-or", [&](Util::CLIParser &parser)
	{
		options.filter_ors.emplace_back(parser.next_string());
	});
	cbs.add("--filter-and", [&](Util::CLIParser &parser)
	{
		options.filter_ands.emplace_back(parser.next_string());
	});
	cbs.add("--filter-negative", [&](Util::CLIParser &parser)
	{
		options.filter_negatives.emplace_back(parser.next_string());
	});
	cbs.add("--max-test-seconds", [&](Util::CLIParser &parser)
	{
		options.max_seconds_per_run = parser.next_double();
	});

	Util::CLIParser parser(std::move(cbs), argc - 1, argv + 1);
	if (!parser.parse())
	{
		LOGE("Failed to parse.\n");
		print_help();
		return EXIT_FAILURE;
	}

	if (d3d12.empty())
		d3d12 = vkd3d_proton ? "d3d12core.dll" : "d3d12.dll";

	if (!device.init(d3d12, validate, vkd3d_proton))
	{
		LOGE("Failed to create device.\n");
		return EXIT_FAILURE;
	}

	if (self_test)
		run_self_tests();
	run_benchmarks();
	device.wait_idle();

	auto csv = results.generate_csv();

	if (output.empty())
	{
		LOGI("\n%s\n", csv.c_str());
	}
	else
	{
		FILE *f = fopen(output.c_str(), "w");
		if (f)
		{
			fputs(csv.c_str(), f);
			fclose(f);
		}
		else
		{
			LOGE("Failed to write CSV to %s\n", output.c_str());
		}
	}

	shaders = {};
	device = {};
}
