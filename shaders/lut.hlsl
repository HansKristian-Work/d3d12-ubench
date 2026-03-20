/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

template <int N>
struct RootConst
{
    float4 value[N];
};

ConstantBuffer<RootConst<4096> > CbufFullRootDesc : register(b0);

static const float4 LUT4x4[4] = {
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8.234324),
	float4(30.234234, 5, 2, 4),
	float4(5, 10, 7.234324, 9),
};

static const float4 LUT8x4[8] = {
	float4(10, 5, 2, 4),
	float4(20.234324, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5.234234, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7.2342, 9),
};

static const float4 LUT16x4[16] = {
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
};

static const float4 LUT32x4[32] = {
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
};

static const float4 LUT500x4[32 * 7] = {
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),

	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10.234, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),

	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10.234, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),

	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10.234324, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),

	float4(10, 5, 2, 4),
	float4(20, 40, 5.23432, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),

	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8.23432),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),

	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 11, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2.23423, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 2, 4),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(20.234234, 40, 5, 8),
	float4(30, 5.23432, 2, 4),
	float4(5, 10, 7.23432, 9),
	float4(10, 5, 11, 4.234324),
	float4(20, 40, 5, 8),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
	float4(10, 5, 9, 4),
	float4(10000.234324, 40, 20, 90),
	float4(30, 5, 2, 4),
	float4(5, 10, 7, 9),
};


cbuffer LoopCounter : register(b1)
{
	int counter;
};

StructuredBuffer<float4> LUTSRV : register(t0);

RWTexture2D<float4> RWTex2D_float4 : register(u0, space0);

#define CBVRootDescRS "CBV(b0), " \
	"RootConstants(b1, num32BitConstants = 1), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded)), " \
	"SRV(t0)"

void ConsumeValue(uint2 thr, float4 values)
{
    RWTex2D_float4[thr] = values;
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut4_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT4x4[(5 * gid + 3 * i) % 4]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut8_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT8x4[(5 * gid + 3 * i) % 8]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut16_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT16x4[(5 * gid + 3 * i) % 16]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut32_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT32x4[(5 * gid + 3 * i) % 32]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut_huge_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT500x4[(5 * gid + 3 * i) % (32 * 7)]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut_cbv_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * CbufFullRootDesc.value[(5 * gid + 3 * i) % 4096]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut_srv_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx + float4(thr.xyxy);
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUTSRV[(5 * gid + 3 * i) % 4096]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut4_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT4x4[(5 * thr.x + 3 * i) % 4]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut8_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT8x4[(5 * thr.x + 3 * i) % 8]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut16_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT16x4[(5 * thr.x + 3 * i) % 16]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut32_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT32x4[(5 * thr.x + 3 * i) % 32]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut_huge_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUT500x4[(5 * thr.x + 3 * i) % (32 * 7)]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut_cbv_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * CbufFullRootDesc.value[(5 * thr.x + 3 * i) % 4096]);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void lut_srv_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    for (int i = 0; i < counter; i++)
        values = saturate((values + 1.0) * LUTSRV[(5 * thr.x + 3 * i) % 4096]);

    ConsumeValue(thr, values);
}

