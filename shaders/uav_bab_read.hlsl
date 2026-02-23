struct Uint5 { uint3 a; uint2 b; };
struct Uint6 { uint3 a; uint3 b; };
struct Uint7 { uint3 a; uint4 b; };
struct Uint8 { uint4 a; uint4 b; };

RWByteAddressBuffer BAB : register(u0, space0);
RWByteAddressBuffer RWTexBuf[] : register(u0, space1);

cbuffer RootConstants : register(b0)
{
	uint offset;
	uint stride;
};

#define RS \
	"DescriptorTable(" \
	"UAV(u0, space = 0, offset = 0, numDescriptors = unbounded))," \
	"DescriptorTable(" \
	"UAV(u0, space = 1, offset = 0, numDescriptors = unbounded))," \
	"RootConstants(b0, num32BitConstants = 2)"

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.x += BAB.Load<uint>(4 * (thr + 32 * i));

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.x += BAB.Load<uint>(4 * (thr + 32 * i));
		v.y += BAB.Load<uint>(4 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.x += BAB.Load<uint>(4 * (thr + 32 * i));
		v.y += BAB.Load<uint>(4 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xy += BAB.Load<uint2>(8 * (thr + 32 * i));

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xy += BAB.Load<uint2>(8 * (thr + 32 * i));
		v.zw += BAB.Load<uint2>(8 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xy += BAB.Load<uint2>(4 * (thr + 32 * i));
		v.zw += BAB.Load<uint2>(4 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xyz += BAB.Load<uint3>(12 * (thr + 32 * i));

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xyz += BAB.Load<uint3>(12 * (thr + 32 * i));
		v.yzw += BAB.Load<uint3>(12 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xyz += BAB.Load<uint3>(4 * (thr + 32 * i));
		v.yzw += BAB.Load<uint3>(4 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v += BAB.Load<uint4>(16 * (thr + 32 * i));

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v += BAB.Load<uint4>(16 * (thr + 32 * i));
		v += BAB.Load<uint4>(16 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v += BAB.Load<uint4>(4 * (thr + 32 * i));
		v += BAB.Load<uint4>(4 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = BAB.Load<Uint5>(20 * (thr + 32 * i));
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = BAB.Load<Uint5>(20 * (thr + 32 * i));
		v.xyz += t.a;
		v.zw += t.b;

		t = BAB.Load<Uint5>(20 * (gid.x + i));
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = BAB.Load<Uint5>(4 * (thr + 32 * i));
		v.xyz += t.a;
		v.zw += t.b;

		t = BAB.Load<Uint5>(4 * (gid.x + i));
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = BAB.Load<Uint6>(24 * (thr + 32 * i));
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = BAB.Load<Uint6>(24 * (thr + 32 * i));
		v.xyz += t.a;
		v.yzw += t.b;

		t = BAB.Load<Uint6>(24 * (gid.x + i));
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = BAB.Load<Uint6>(4 * (thr + 32 * i));
		v.xyz += t.a;
		v.yzw += t.b;

		t = BAB.Load<Uint6>(4 * (gid.x + i));
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = BAB.Load<Uint7>(28 * (thr + 32 * i));
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = BAB.Load<Uint7>(28 * (thr + 32 * i));
		v.xyz += t.a;
		v += t.b;

		t = BAB.Load<Uint7>(28 * (gid.x + i));
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = BAB.Load<Uint7>(4 * (thr + 32 * i));
		v.xyz += t.a;
		v += t.b;

		t = BAB.Load<Uint7>(4 * (gid.x + i));
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_vmem_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = BAB.Load<Uint8>(32 * (thr + 32 * i));
		v += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_mixed_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = BAB.Load<Uint8>(32 * (thr + 32 * i));
		v += t.a;
		v += t.b;

		t = BAB.Load<Uint8>(32 * (gid.x + i));
		v += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void uav_bab_read_unaligned_uint8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint4 v = uint4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = BAB.Load<Uint8>(4 * (thr + 32 * i));
		v += t.a;
		v += t.b;

		t = BAB.Load<Uint8>(4 * (gid.x + i));
		v += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store4(16 * thr, v);
}

