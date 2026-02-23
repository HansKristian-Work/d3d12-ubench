/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

Texture2D<uint> Tex2D_uint1[] : register(t0, space0);
Texture2D<uint2> Tex2D_uint2[] : register(t0, space1);
Texture2D<uint3> Tex2D_uint3[] : register(t0, space2);
Texture2D<uint4> Tex2D_uint4[] : register(t0, space3);
RWTexture2D<uint4> RWTex2D_uint4[] : register(u0, space0);

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
void srv_2d_bindless_divergent_throughput(uint2 thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr.x ^ (i * 5)) & ((1 << 19) - 1);
		v.x += Tex2D_uint1[NonUniformResourceIndex(index ^ 0)][thr];
		v.xy += Tex2D_uint2[NonUniformResourceIndex(index ^ 1)][thr];
		v.xyz += Tex2D_uint3[NonUniformResourceIndex(index ^ 2)][thr];
		v += Tex2D_uint4[NonUniformResourceIndex(index ^ 3)][thr];
	}

	RWTex2D_uint4[NonUniformResourceIndex(thr.x)][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_divergent_throughput_low_occupancy(uint2 thr : SV_DispatchThreadID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr.x ^ (i * 5)) & ((1 << 19) - 1);
		v.x += Tex2D_uint1[NonUniformResourceIndex(index ^ 0)][thr];
		v.xy += Tex2D_uint2[NonUniformResourceIndex(index ^ 1)][thr];
		v.xyz += Tex2D_uint3[NonUniformResourceIndex(index ^ 2)][thr];
		v += Tex2D_uint4[NonUniformResourceIndex(index ^ 3)][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTex2D_uint4[NonUniformResourceIndex(thr.x)][thr] = v + grs[lid];
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_divergent_latency(uint2 thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 1023;
		v.x += Tex2D_uint1[NonUniformResourceIndex(index ^ v.w)][thr];
		v.xy += Tex2D_uint2[NonUniformResourceIndex(index ^ v.x)][thr];
		v.xyz += Tex2D_uint3[NonUniformResourceIndex(index ^ v.y)][thr];
		v += Tex2D_uint4[NonUniformResourceIndex(index ^ v.z)][thr];
	}

	RWTex2D_uint4[NonUniformResourceIndex(thr.x)][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_divergent_latency_low_occupancy(uint2 thr : SV_DispatchThreadID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 1023;
		v.x += Tex2D_uint1[NonUniformResourceIndex(index ^ v.w)][thr];
		v.xy += Tex2D_uint2[NonUniformResourceIndex(index ^ v.x)][thr];
		v.xyz += Tex2D_uint3[NonUniformResourceIndex(index ^ v.y)][thr];
		v += Tex2D_uint4[NonUniformResourceIndex(index ^ v.z)][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTex2D_uint4[NonUniformResourceIndex(thr.x)][thr] = v + grs[lid];
}


[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_coherent_throughput(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 1023;
		v.x += Tex2D_uint1[index ^ 0][thr];
		v.xy += Tex2D_uint2[index ^ 1][thr];
		v.xyz += Tex2D_uint3[index ^ 2][thr];
		v += Tex2D_uint4[index ^ 3][thr];
	}

	RWTex2D_uint4[gid.x][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_coherent_throughput_low_occupancy(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 1023;
		v.x += Tex2D_uint1[index ^ 0][thr];
		v.xy += Tex2D_uint2[index ^ 1][thr];
		v.xyz += Tex2D_uint3[index ^ 2][thr];
		v += Tex2D_uint4[index ^ 3][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTex2D_uint4[gid.x][thr] = v + grs[lid];
}


[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_coherent_latency(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 1023;
		v.x += Tex2D_uint1[WaveReadLaneFirst(index ^ v.w)][thr];
		v.xy += Tex2D_uint2[WaveReadLaneFirst(index ^ v.x)][thr];
		v.xyz += Tex2D_uint3[WaveReadLaneFirst(index ^ v.y)][thr];
		v += Tex2D_uint4[WaveReadLaneFirst(index ^ v.z)][thr];
	}

	RWTex2D_uint4[gid.x][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_2d_bindless_coherent_latency_low_occupancy(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID, uint lid : SV_GroupIndex)
{
	uint4 v = uint4(0, 0, 0, 0);

	for (int i = lid; i < 8 * 1024; i += 32)
		grs[i] = 0;
	GroupMemoryBarrierWithGroupSync();

	for (int i = 0; i < 64; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 1023;
		v.x += Tex2D_uint1[WaveReadLaneFirst((index ^ v.w) & 1023)][thr];
		v.xy += Tex2D_uint2[WaveReadLaneFirst(index ^ v.x) & 1023][thr];
		v.xyz += Tex2D_uint3[WaveReadLaneFirst(index ^ v.y) & 1023][thr];
		v += Tex2D_uint4[WaveReadLaneFirst(index ^ v.z) & 1023][thr];
		uint o;
		InterlockedAdd(grs[8 * 1024 - 1 - i * 33], 1, o);
	}

	GroupMemoryBarrierWithGroupSync();
	RWTex2D_uint4[gid.x][thr] = v + grs[lid];
}

