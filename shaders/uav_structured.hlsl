/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

struct Uint5 { uint3 a; uint2 b; };
struct Uint6 { uint3 a; uint3 b; };
struct Uint7 { uint3 a; uint4 b; };
struct Uint8 { uint4 a; uint4 b; };

RWStructuredBuffer<uint> Struct_uint1 : register(u0, space0);
RWStructuredBuffer<uint2> Struct_uint2 : register(u1, space0);
RWStructuredBuffer<uint3> Struct_uint3 : register(u2, space0);
RWStructuredBuffer<uint4> Struct_uint4 : register(u3, space0);
RWStructuredBuffer<Uint5> Struct_uint5 : register(u4, space0);
RWStructuredBuffer<Uint6> Struct_uint6 : register(u5, space0);
RWStructuredBuffer<Uint7> Struct_uint7 : register(u6, space0);
RWStructuredBuffer<Uint8> Struct_uint8 : register(u7, space0);

RWStructuredBuffer<uint> Struct_uint1_arr[] : register(u0, space0);
RWStructuredBuffer<uint2> Struct_uint2_arr[] : register(u1, space0);
RWStructuredBuffer<uint3> Struct_uint3_arr[] : register(u2, space0);
RWStructuredBuffer<uint4> Struct_uint4_arr[] : register(u3, space0);
RWStructuredBuffer<Uint5> Struct_uint5_arr[] : register(u4, space0);
RWStructuredBuffer<Uint6> Struct_uint6_arr[] : register(u5, space0);
RWStructuredBuffer<Uint7> Struct_uint7_arr[] : register(u6, space0);
RWStructuredBuffer<Uint8> Struct_uint8_arr[] : register(u7, space0);

cbuffer RootConstants : register(b0)
{
	uint offset;
	uint stride;
	uint loop_count;
};

#define RS \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))," \
	"RootConstants(b0, num32BitConstants = 3)"

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint1[thr + 32 * i] = thr;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint2[thr + 32 * i] = uint2(thr, thr + 1);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint3[thr + 32 * i] = uint3(thr, thr + 1, thr + 2);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint4[thr + 32 * i] = uint4(thr, thr + 1, thr + 2, thr + 3);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t;
		t.a = uint3(thr, thr + 1, thr + 2);
		t.b = uint2(thr + 3, thr + 4);
		Struct_uint5[thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t;
		t.a = uint3(thr + 0, thr + 1, thr + 2);
		t.b = uint3(thr + 3, thr + 4, thr + 5);
		Struct_uint6[thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t;
		t.a = uint3(thr + 0, thr + 1, thr + 2);
		t.b = uint4(thr + 3, thr + 4, thr + 5, thr + 6);
		Struct_uint7[thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t;
		t.a = uint4(thr + 0, thr + 1, thr + 2, thr + 3);
		t.b = uint4(thr + 4, thr + 5, thr + 6, thr + 7);
		Struct_uint8[thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint1_arr[offset + stride * i][thr + 32 * i] = thr;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint2_arr[offset + stride * i][thr + 32 * i] = uint2(thr, thr + 1);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint3_arr[offset + stride * i][thr + 32 * i] = uint3(thr, thr + 1, thr + 2);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
		Struct_uint4_arr[offset + stride * i][thr + 32 * i] = uint4(thr, thr + 1, thr + 2, thr + 3);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t;
		t.a = uint3(thr, thr + 1, thr + 2);
		t.b = uint2(thr + 3, thr + 4);
		Struct_uint5_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t;
		t.a = uint3(thr + 0, thr + 1, thr + 2);
		t.b = uint3(thr + 3, thr + 4, thr + 5);
		Struct_uint6_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t;
		t.a = uint3(thr + 0, thr + 1, thr + 2);
		t.b = uint4(thr + 3, thr + 4, thr + 5, thr + 6);
		Struct_uint7_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t;
		t.a = uint4(thr + 0, thr + 1, thr + 2, thr + 3);
		t.b = uint4(thr + 4, thr + 5, thr + 6, thr + 7);
		Struct_uint8_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
		Struct_uint1_arr[offset + stride * i][thr + 32 * i] = thr;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
		Struct_uint2_arr[offset + stride * i][thr + 32 * i] = uint2(thr, thr + 1);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
		Struct_uint3_arr[offset + stride * i][thr + 32 * i] = uint3(thr, thr + 1, thr + 2);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
		Struct_uint4_arr[offset + stride * i][thr + 32 * i] = uint4(thr, thr + 1, thr + 2, thr + 3);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
	{
		Uint5 t;
		t.a = uint3(thr, thr + 1, thr + 2);
		t.b = uint2(thr + 3, thr + 4);
		Struct_uint5_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
	{
		Uint6 t;
		t.a = uint3(thr + 0, thr + 1, thr + 2);
		t.b = uint3(thr + 3, thr + 4, thr + 5);
		Struct_uint6_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
	{
		Uint7 t;
		t.a = uint3(thr + 0, thr + 1, thr + 2);
		t.b = uint4(thr + 3, thr + 4, thr + 5, thr + 6);
		Struct_uint7_arr[offset + stride * i][thr + 32 * i] = t;
	}
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_structured_buffer_bindless_loop_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	for (int i = 0; i < loop_count; i++)
	{
		Uint8 t;
		t.a = uint4(thr + 0, thr + 1, thr + 2, thr + 3);
		t.b = uint4(thr + 4, thr + 5, thr + 6, thr + 7);
		Struct_uint8_arr[offset + stride * i][thr + 32 * i] = t;
	}
}
