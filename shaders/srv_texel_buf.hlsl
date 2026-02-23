/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

Buffer<uint> TexBuf_uint1[] : register(t0, space0);
Buffer<uint2> TexBuf_uint2[] : register(t0, space1);
Buffer<uint3> TexBuf_uint3[] : register(t0, space2);
Buffer<uint4> TexBuf_uint4[] : register(t0, space3);
RWBuffer<uint4> RWTexBuf_uint4[] : register(u0, space0);

#define BindlessTexturesRS "DescriptorTable(" \
	"SRV(t0, space = 0, offset = 0, numDescriptors = unbounded), " \
	"SRV(t0, space = 1, offset = 0, numDescriptors = unbounded)," \
	"SRV(t0, space = 2, offset = 0, numDescriptors = unbounded), " \
	"SRV(t0, space = 3, offset = 0, numDescriptors = unbounded)), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

groupshared uint grs[8 * 1024];

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_divergent_throughput(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr ^ (i * 5)) & ((1 << 19) - 1);
		v.x += TexBuf_uint1[NonUniformResourceIndex(index ^ 0)][thr];
		v.xy += TexBuf_uint2[NonUniformResourceIndex(index ^ 1)][thr];
		v.xyz += TexBuf_uint3[NonUniformResourceIndex(index ^ 2)][thr];
		v += TexBuf_uint4[NonUniformResourceIndex(index ^ 3)][thr];
	}

	RWTexBuf_uint4[NonUniformResourceIndex(thr)][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_divergent_throughput_low_occupancy(uint thr : SV_DispatchThreadID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr ^ (i * 5)) & ((1 << 19) - 1);
		v.x += TexBuf_uint1[NonUniformResourceIndex(index ^ 0)][thr];
		v.xy += TexBuf_uint2[NonUniformResourceIndex(index ^ 1)][thr];
		v.xyz += TexBuf_uint3[NonUniformResourceIndex(index ^ 2)][thr];
		v += TexBuf_uint4[NonUniformResourceIndex(index ^ 3)][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTexBuf_uint4[NonUniformResourceIndex(thr)][thr] = v + grs[lid];
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_divergent_latency(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr ^ (i * 5)) & 1023;
		v.x += TexBuf_uint1[NonUniformResourceIndex(index ^ v.w)][thr];
		v.xy += TexBuf_uint2[NonUniformResourceIndex(index ^ v.x)][thr];
		v.xyz += TexBuf_uint3[NonUniformResourceIndex(index ^ v.y)][thr];
		v += TexBuf_uint4[NonUniformResourceIndex(index ^ v.z)][thr];
	}

	RWTexBuf_uint4[NonUniformResourceIndex(thr)][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_divergent_latency_low_occupancy(uint thr : SV_DispatchThreadID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr ^ (i * 5)) & 1023;
		v.x += TexBuf_uint1[NonUniformResourceIndex(index ^ v.w)][thr];
		v.xy += TexBuf_uint2[NonUniformResourceIndex(index ^ v.x)][thr];
		v.xyz += TexBuf_uint3[NonUniformResourceIndex(index ^ v.y)][thr];
		v += TexBuf_uint4[NonUniformResourceIndex(index ^ v.z)][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTexBuf_uint4[NonUniformResourceIndex(thr)][thr] = v + grs[lid];
}


[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_coherent_throughput(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 1023;
		v.x += TexBuf_uint1[index ^ 0][thr];
		v.xy += TexBuf_uint2[index ^ 1][thr];
		v.xyz += TexBuf_uint3[index ^ 2][thr];
		v += TexBuf_uint4[index ^ 3][thr];
	}

	RWTexBuf_uint4[gid.x][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_coherent_throughput_low_occupancy(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 1023;
		v.x += TexBuf_uint1[index ^ 0][thr];
		v.xy += TexBuf_uint2[index ^ 1][thr];
		v.xyz += TexBuf_uint3[index ^ 2][thr];
		v += TexBuf_uint4[index ^ 3][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTexBuf_uint4[gid.x][thr] = v + grs[lid];
}


[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_coherent_latency(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr ^ (i * 5)) & 1023;
		v.x += TexBuf_uint1[WaveReadLaneFirst(index ^ v.w)][thr];
		v.xy += TexBuf_uint2[WaveReadLaneFirst(index ^ v.x)][thr];
		v.xyz += TexBuf_uint3[WaveReadLaneFirst(index ^ v.y)][thr];
		v += TexBuf_uint4[WaveReadLaneFirst(index ^ v.z)][thr];
	}

	RWTexBuf_uint4[gid.x][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_bindless_coherent_latency_low_occupancy(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = lid; i < 8 * 1024; i += 32)
		grs[i] = 0;
	GroupMemoryBarrierWithGroupSync();

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr ^ (i * 5)) & 1023;
		v.x += TexBuf_uint1[WaveReadLaneFirst((index ^ v.w) & 1023)][thr];
		v.xy += TexBuf_uint2[WaveReadLaneFirst(index ^ v.x) & 1023][thr];
		v.xyz += TexBuf_uint3[WaveReadLaneFirst(index ^ v.y) & 1023][thr];
		v += TexBuf_uint4[WaveReadLaneFirst(index ^ v.z) & 1023][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTexBuf_uint4[gid.x][thr] = v + grs[lid];
}

