/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

Buffer<uint> TexBuf_uint1 : register(t0, space0);
Buffer<uint2> TexBuf_uint2 : register(t0, space0);
Buffer<uint3> TexBuf_uint3 : register(t0, space0);
Buffer<uint4> TexBuf_uint4 : register(t0, space0);

StructuredBuffer<uint> Buf_uint1 : register(t0, space0);
StructuredBuffer<uint2> Buf_uint2 : register(t0, space0);
StructuredBuffer<uint3> Buf_uint3 : register(t0, space0);
StructuredBuffer<uint4> Buf_uint4 : register(t0, space0);

ByteAddressBuffer BAB : register(t0, space0);

RWBuffer<uint4> RWTexBuf_uint4 : register(u0, space0);

cbuffer Constants : register(b0)
{
	uint thread_stride;
	uint iteration_stride;
	uint LOOP_COUNT;
};

#define BindlessTexturesRS "DescriptorTable(" \
	"SRV(t0, space = 0, offset = 0, numDescriptors = unbounded)), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded)), " \
	"RootConstants(b0, num32BitConstants = 3)"

void ConsumeValue(uint thr, uint4 values)
{
    uint first_value = WaveReadLaneFirst(values.x);
    if (first_value == 10012315)
        RWTexBuf_uint4[thr] = values;
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint1(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.x += TexBuf_uint1[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint1_const_iter_stride(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.x += TexBuf_uint1[thr.x * thread_stride + i * 32];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint2(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xy += TexBuf_uint2[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint2_const_iter_stride(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xy += TexBuf_uint2[thr.x * thread_stride + i * 32];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint3(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xyz += TexBuf_uint3[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint3_const_iter_stride(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xyz += TexBuf_uint3[thr.x * thread_stride + i * 32];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint4(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v += TexBuf_uint4[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_texel_buf_strided_uint4_const_iter_stride(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v += TexBuf_uint4[thr.x * thread_stride + i * 32];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_structured_strided_uint1(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.x += Buf_uint1[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_structured_strided_uint2(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xy += Buf_uint2[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_structured_strided_uint3(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xyz += Buf_uint3[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_structured_strided_uint4(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v += Buf_uint4[thr.x * thread_stride + i * iteration_stride];
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_unaligned_uint1(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.x += BAB.Load<uint>(thr.x * thread_stride + i * iteration_stride);
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_unaligned_uint2(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xy += BAB.Load<uint2>(thr.x * thread_stride + i * iteration_stride);
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_unaligned_uint3(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xyz += BAB.Load<uint3>(thr.x * thread_stride + i * iteration_stride);
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_unaligned_uint4(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v += BAB.Load<uint4>(thr.x * thread_stride + i * iteration_stride);
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_aligned_uint1(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.x += BAB.Load<uint>(4 * (thr.x * thread_stride + i * iteration_stride));
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_aligned_uint2(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xy += BAB.Load<uint2>(8 * (thr.x * thread_stride + i * iteration_stride));
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_aligned_uint3(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v.xyz += BAB.Load<uint3>(12 * (thr.x * thread_stride + i * iteration_stride));
	ConsumeValue(thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(BindlessTexturesRS)]
void srv_bab_strided_aligned_uint4(uint thr : SV_DispatchThreadID)
{
	uint4 v = uint4(0, 0, 0, 0);
	for (int i = 0; i < LOOP_COUNT; i++)
		v += BAB.Load<uint4>(16 * (thr.x * thread_stride + i * iteration_stride));
	ConsumeValue(thr, v);
}

