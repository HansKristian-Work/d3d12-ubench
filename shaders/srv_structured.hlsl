/* Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
 * SPDX-License-Identifier: MIT
 */

struct Uint5 { uint3 a; uint2 b; };
struct Uint6 { uint3 a; uint3 b; };
struct Uint7 { uint3 a; uint4 b; };
struct Uint8 { uint4 a; uint4 b; };

StructuredBuffer<uint> Struct_uint1 : register(t0, space0);
StructuredBuffer<uint2> Struct_uint2 : register(t1, space0);
StructuredBuffer<uint3> Struct_uint3 : register(t2, space0);
StructuredBuffer<uint4> Struct_uint4 : register(t3, space0);
StructuredBuffer<Uint5> Struct_uint5 : register(t4, space0);
StructuredBuffer<Uint6> Struct_uint6 : register(t5, space0);
StructuredBuffer<Uint7> Struct_uint7 : register(t6, space0);
StructuredBuffer<Uint8> Struct_uint8 : register(t7, space0);

StructuredBuffer<uint> Struct_uint1_arr[] : register(t0, space0);
StructuredBuffer<uint2> Struct_uint2_arr[] : register(t1, space0);
StructuredBuffer<uint3> Struct_uint3_arr[] : register(t2, space0);
StructuredBuffer<uint4> Struct_uint4_arr[] : register(t3, space0);
StructuredBuffer<Uint5> Struct_uint5_arr[] : register(t4, space0);
StructuredBuffer<Uint6> Struct_uint6_arr[] : register(t5, space0);
StructuredBuffer<Uint7> Struct_uint7_arr[] : register(t6, space0);
StructuredBuffer<Uint8> Struct_uint8_arr[] : register(t7, space0);

RWStructuredBuffer<uint4> RWTexBuf_uint4[] : register(u0, space0);

cbuffer RootConstants : register(b0)
{
	uint offset;
	uint stride;
};

#define RS \
	"DescriptorTable(" \
	"SRV(t0, space = 0, offset = 0, numDescriptors = unbounded)), " \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))," \
	"RootConstants(b0, num32BitConstants = 2)"

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.x += Struct_uint1[thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.x += Struct_uint1[thr + 32 * i];
		v.y += Struct_uint1[gid.x + i];
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xy += Struct_uint2[thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xy += Struct_uint2[thr + 32 * i];
		v.zw += Struct_uint2[gid.x + i];
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xyz += Struct_uint3[thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xyz += Struct_uint3[thr + 32 * i];
		v.yzw += Struct_uint3[gid.x + i];
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v += Struct_uint4[thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v += Struct_uint4[thr + 32 * i];
		v += Struct_uint4[gid.x + i];
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = Struct_uint5[thr + 32 * i];
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = Struct_uint5[thr + 32 * i];
		v.xyz += t.a;
		v.zw += t.b;

		t = Struct_uint5[gid.x + i];
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = Struct_uint6[thr + 32 * i];
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = Struct_uint6[thr + 32 * i];
		v.xyz += t.a;
		v.yzw += t.b;

		t = Struct_uint6[gid.x + i];
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = Struct_uint7[thr + 32 * i];
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = Struct_uint7[thr + 32 * i];
		v.xyz += t.a;
		v += t.b;

		t = Struct_uint7[gid.x + i];
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_vmem_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = Struct_uint8[thr + 32 * i];
		v += t.a;
		v += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_mixed_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = Struct_uint8[thr + 32 * i];
		v += t.a;
		v += t.b;

		t = Struct_uint8[gid.x + i];
		v += t.a;
		v += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.x += Struct_uint1_arr[offset + stride * i][thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xy += Struct_uint2_arr[offset + stride * i][thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xyz += Struct_uint3_arr[offset + stride * i][thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v += Struct_uint4_arr[offset + stride * i][thr + 32 * i];

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = Struct_uint5_arr[offset + stride * i][thr + 32 * i];
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = Struct_uint6_arr[offset + stride * i][thr + 32 * i];
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = Struct_uint7_arr[offset + stride * i][thr + 32 * i];
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_structured_buffer_bindless_vmem_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = Struct_uint8_arr[offset + stride * i][thr + 32 * i];
		v += t.a;
		v += t.b;
	}

	RWTexBuf_uint4[gid.y][thr] = v;
}
