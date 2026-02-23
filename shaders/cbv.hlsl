/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

struct Single
{
    float4 value;
};

template <int N>
struct RootConst
{
    float4 value[N];
};

ConstantBuffer<Single> CbufSmall : register(b0);

ConstantBuffer<RootConst<2> > CbufRootConsts8 : register(b0);
ConstantBuffer<RootConst<4> > CbufRootConsts16 : register(b0);
ConstantBuffer<RootConst<8> > CbufRootConsts32 : register(b0);
ConstantBuffer<RootConst<15> > CbufRootConsts60 : register(b0);

ConstantBuffer<RootConst<4096> > CbufFullRootDesc : register(b0);
ConstantBuffer<Single> Cbufs_bindless[] : register(b0);

ConstantBuffer<RootConst<4096> > CbufFullRootDesc1 : register(b1);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc2 : register(b2);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc3 : register(b3);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc4 : register(b4);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc5 : register(b5);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc6 : register(b6);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc7 : register(b7);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc8 : register(b8);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc9 : register(b9);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc10 : register(b10);
ConstantBuffer<RootConst<4096> > CbufFullRootDesc11 : register(b11);

RWTexture2D<float4> RWTex2D_float4 : register(u0, space0);

#define CBVRootConsts8RS "RootConstants(b0, num32BitConstants = 8)," \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

#define CBVRootConsts16RS "RootConstants(b0, num32BitConstants = 16)," \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

#define CBVRootConsts32RS "RootConstants(b0, num32BitConstants = 32)," \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

#define CBVRootConsts60RS "RootConstants(b0, num32BitConstants = 60)," \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

#define CBVRootDescRS "CBV(b0), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

#define CBVRootDesc4RS "CBV(b0), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))," \
	"CBV(b1), " \
	"CBV(b2), " \
	"CBV(b3)"

#define CBVRootDesc8RS "CBV(b0), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))," \
	"CBV(b1), " \
	"CBV(b2), " \
	"CBV(b3), " \
	"CBV(b4), " \
	"CBV(b5), " \
	"CBV(b6), " \
	"CBV(b7)"

#define CBVRootDesc12RS "CBV(b0), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))," \
	"CBV(b1), " \
	"CBV(b2), " \
	"CBV(b3), " \
	"CBV(b4), " \
	"CBV(b5), " \
	"CBV(b6), " \
	"CBV(b7), " \
	"CBV(b8), " \
	"CBV(b9), " \
	"CBV(b10), " \
	"CBV(b11)"

#define CBVTableRS "DescriptorTable(CBV(b0, space = 0, offset = 0, numDescriptors = unbounded)), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))" \

void ConsumeValue(uint2 thr, float4 values)
{
    float first_value = WaveReadLaneFirst(values.x);
    if (first_value == 10012315)
        RWTex2D_float4[thr] = values;
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootConsts8RS)]
void cbv_root_constants_8_read(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [unroll]
    for (int i = 0; i < 2; i++)
        values *= CbufRootConsts8.value[i] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootConsts16RS)]
void cbv_root_constants_16_read(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [unroll]
    for (int i = 0; i < 4; i++)
        values *= CbufRootConsts16.value[i] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootConsts32RS)]
void cbv_root_constants_32_read(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [unroll]
    for (int i = 0; i < 8; i++)
        values *= CbufRootConsts32.value[i] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootConsts60RS)]
void cbv_root_constants_60_read(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [unroll]
    for (int i = 0; i < 15; i++)
        values *= CbufRootConsts60.value[i] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDesc4RS)]
void cbv_root_desc_4_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    values *= CbufFullRootDesc.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc1.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc2.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc3.value[gid.x] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDesc8RS)]
void cbv_root_desc_8_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    values *= CbufFullRootDesc.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc1.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc2.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc3.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc4.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc5.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc6.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc7.value[gid.x] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDesc12RS)]
void cbv_root_desc_12_read_coherent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    values *= CbufFullRootDesc.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc1.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc2.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc3.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc4.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc5.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc6.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc7.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc8.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc9.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc10.value[gid.x] + float4(thr.xyxy);
    values *= CbufFullRootDesc11.value[gid.x] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDesc4RS)]
void cbv_root_desc_4_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    values *= CbufFullRootDesc.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc1.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc2.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc3.value[thr.x % 4096] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDesc8RS)]
void cbv_root_desc_8_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    values *= CbufFullRootDesc.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc1.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc2.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc3.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc4.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc5.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc6.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc7.value[thr.x % 4096] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDesc12RS)]
void cbv_root_desc_12_read_divergent(uint2 thr : SV_DispatchThreadID, uint gid : SV_GroupID)
{
    float4 values = 1.0.xxxx;
    values *= CbufFullRootDesc.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc1.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc2.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc3.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc4.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc5.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc6.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc7.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc8.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc9.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc10.value[thr.x % 4096] + float4(thr.xyxy);
    values *= CbufFullRootDesc11.value[thr.x % 4096] + float4(thr.xyxy);
    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void cbv_root_desc_read_coherent(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [loop]
    for (int i = 0; i < 4096; i++)
        values *= CbufFullRootDesc.value[i] + float4(thr.xyxy);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVRootDescRS)]
void cbv_root_desc_read_divergent(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [loop]
    for (int i = 0; i < 512; i++)
        values *= CbufFullRootDesc.value[i ^ thr.x] + float4(thr.yyyy);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVTableRS)]
void cbv_root_table_read_coherent(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [loop]
    for (int i = 0; i < 4096; i++)
        values *= CbufFullRootDesc.value[i] + float4(thr.xyxy);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVTableRS)]
void cbv_root_table_read_divergent(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [loop]
    for (int i = 0; i < 512; i++)
        values *= CbufFullRootDesc.value[i ^ thr.x] + float4(thr.yyyy);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVTableRS)]
void cbv_root_table_bindless_coherent(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [loop]
    for (int i = 0; i < 1024; i++)
        values *= Cbufs_bindless[i].value + float4(thr.xyxy);

    ConsumeValue(thr, values);
}

[numthreads(32, 1, 1)]
[RootSignature(CBVTableRS)]
void cbv_root_table_bindless_divergent(uint2 thr : SV_DispatchThreadID)
{
    float4 values = 1.0.xxxx;
    [loop]
    for (int i = 0; i < 1024; i++)
        values *= Cbufs_bindless[NonUniformResourceIndex((i ^ thr.x) & 1023)].value + float4(thr.yyyy);

    ConsumeValue(thr, values);
}
