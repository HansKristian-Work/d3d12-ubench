/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

RWTexture2D<uint4> RWTex2D_uint4[] : register(u0, space0);
RWBuffer<uint1> RWBuf_uint1[] : register(u0, space0);
RWBuffer<uint2> RWBuf_uint2[] : register(u0, space0);
RWBuffer<uint3> RWBuf_uint3[] : register(u0, space0);
RWBuffer<uint4> RWBuf_uint4[] : register(u0, space0);

#define BindlessTexturesRS \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_2d_bindless_divergent(uint2 thr : SV_DispatchThreadID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 4095;
		RWTex2D_uint4[NonUniformResourceIndex(index)][thr] = thr.xyxy;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_2d_bindless_coherent(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 4095;
		RWTex2D_uint4[index][thr] = thr.xyxy;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint1_bindless_divergent(uint2 thr : SV_DispatchThreadID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 4095;
		RWBuf_uint1[NonUniformResourceIndex(index)][thr.x] = thr.x;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint1_bindless_coherent(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 4095;
		RWBuf_uint1[index][thr.x] = thr.x;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint2_bindless_divergent(uint2 thr : SV_DispatchThreadID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 4095;
		RWBuf_uint2[NonUniformResourceIndex(index)][thr.x] = thr.xy;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint2_bindless_coherent(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 4095;
		RWBuf_uint2[index][thr.x] = thr.xy;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint3_bindless_divergent(uint2 thr : SV_DispatchThreadID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 4095;
		RWBuf_uint3[NonUniformResourceIndex(index)][thr.x] = thr.xyx;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint3_bindless_coherent(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 4095;
		RWBuf_uint3[index][thr.x] = thr.xyx;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint4_bindless_divergent(uint2 thr : SV_DispatchThreadID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (thr.x ^ (i * 5)) & 4095;
		RWBuf_uint4[NonUniformResourceIndex(index)][thr.x] = thr.xyxy;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void uav_write_uint4_bindless_coherent(uint2 thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < 256; i++)
	{
		uint index = (gid.x ^ (i * 5)) & 4095;
		RWBuf_uint4[index][thr.x] = thr.xyxy;
	}
}

