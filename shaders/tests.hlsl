/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

Texture2D<uint> Tex2D_uint : register(t0, space0);
RWTexture2D<uint> RWTex2D_uint : register(u0, space0);
Texture2D<float> Tex2D_float : register(t0, space1);
RWTexture2D<float2> RWTex2D_float2 : register(u0, space1);

SamplerState S[2] : register(s0, space0);

#define UintRS "DescriptorTable(SRV(t0, offset = 0), UAV(u0, offset = 1))"
#define FloatRS "DescriptorTable(SRV(t0, space = 1, offset = 0), UAV(u0, space = 1, offset = 1)), DescriptorTable(Sampler(s0, numDescriptors = 2))"

[numthreads(8, 8, 1)]
[RootSignature(UintRS)]
void basic_copy_srv_uav_2d(uint2 thr : SV_DispatchThreadID)
{
	RWTex2D_uint[thr] = Tex2D_uint[thr];
}

[numthreads(8, 8, 1)]
[RootSignature(FloatRS)]
void basic_sampled_texture(uint2 thr : SV_DispatchThreadID)
{
	RWTex2D_float2[thr] = float2(
		Tex2D_float.SampleLevel(S[0], 1.5.xx, 0.0),
		Tex2D_float.SampleLevel(S[1], 1.5.xx, 0.0));
}

StructuredBuffer<uint> StructBuf : register(t0);
RWStructuredBuffer<uint> RWStructBuf : register(u0);

cbuffer Blah : register(b0)
{
	uint offset;
};

cbuffer OtherBlah : register(b1)
{
	uint4 values;
}

[numthreads(64, 1, 1)]
#define RootDescRS "SRV(t0), UAV(u0), CBV(b0), RootConstants(b1, num32BitConstants = 4)"
[RootSignature(RootDescRS)]
void copy_root_desc(uint thr : SV_DispatchThreadID)
{
	uint4 tmp = values;
	RWStructBuf[thr] = StructBuf[thr] + offset + tmp[thr & 3];
}
