struct Uint5 { uint16_t3 a; uint16_t2 b; };
struct Uint6 { uint16_t3 a; uint16_t3 b; };
struct Uint7 { uint16_t3 a; uint16_t4 b; };
struct Uint8 { uint16_t4 a; uint16_t4 b; };

ByteAddressBuffer BAB : register(t0, space0);
RWByteAddressBuffer RWTexBuf[] : register(u0, space0);

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
void srv_bab_vmem_uint16_1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.x += BAB.Load<uint16_t>(2 * (thr + 32 * i));

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.x += BAB.Load<uint16_t>(2 * (thr + 32 * i));
		v.y += BAB.Load<uint16_t>(2 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_1(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.x += BAB.Load<uint16_t>(2 * (thr + 32 * i));
		v.y += BAB.Load<uint16_t>(2 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xy += BAB.Load<uint16_t2>(4 * (thr + 32 * i));

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xy += BAB.Load<uint16_t2>(4 * (thr + 32 * i));
		v.zw += BAB.Load<uint16_t2>(4 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_2(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xy += BAB.Load<uint16_t2>(2 * (thr + 32 * i));
		v.zw += BAB.Load<uint16_t2>(2 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v.xyz += BAB.Load<uint16_t3>(6 * (thr + 32 * i));

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xyz += BAB.Load<uint16_t3>(6 * (thr + 32 * i));
		v.yzw += BAB.Load<uint16_t3>(6 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_3(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v.xyz += BAB.Load<uint16_t3>(2 * (thr + 32 * i));
		v.yzw += BAB.Load<uint16_t3>(2 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
		v += BAB.Load<uint16_t4>(8 * (thr + 32 * i));

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v += BAB.Load<uint16_t4>(8 * (thr + 32 * i));
		v += BAB.Load<uint16_t4>(8 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_4(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		v += BAB.Load<uint16_t4>(2 * (thr + 32 * i));
		v += BAB.Load<uint16_t4>(2 * (gid.x + i));
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}


[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = BAB.Load<Uint5>(10 * (thr + 32 * i));
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = BAB.Load<Uint5>(10 * (thr + 32 * i));
		v.xyz += t.a;
		v.zw += t.b;

		t = BAB.Load<Uint5>(10 * (gid.x + i));
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_5(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint5 t = BAB.Load<Uint5>(2 * (thr + 32 * i));
		v.xyz += t.a;
		v.zw += t.b;

		t = BAB.Load<Uint5>(2 * (gid.x + i));
		v.xyz += t.a;
		v.zw += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = BAB.Load<Uint6>(12 * (thr + 32 * i));
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = BAB.Load<Uint6>(12 * (thr + 32 * i));
		v.xyz += t.a;
		v.yzw += t.b;

		t = BAB.Load<Uint6>(12 * (gid.x + i));
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_6(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint6 t = BAB.Load<Uint6>(2 * (thr + 32 * i));
		v.xyz += t.a;
		v.yzw += t.b;

		t = BAB.Load<Uint6>(2 * (gid.x + i));
		v.xyz += t.a;
		v.yzw += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = BAB.Load<Uint7>(14 * (thr + 32 * i));
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = BAB.Load<Uint7>(14 * (thr + 32 * i));
		v.xyz += t.a;
		v += t.b;

		t = BAB.Load<Uint7>(14 * (gid.x + i));
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_7(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint7 t = BAB.Load<Uint7>(2 * (thr + 32 * i));
		v.xyz += t.a;
		v += t.b;

		t = BAB.Load<Uint7>(2 * (gid.x + i));
		v.xyz += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_vmem_uint16_8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = BAB.Load<Uint8>(16 * (thr + 32 * i));
		v += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_mixed_uint16_8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = BAB.Load<Uint8>(16 * (thr + 32 * i));
		v += t.a;
		v += t.b;

		t = BAB.Load<Uint8>(16 * (gid.x + i));
		v += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

[numthreads(32, 1, 1)]
[RootSignature(RS)]
void srv_bab_unaligned_uint16_8(uint thr : SV_DispatchThreadID, uint2 gid : SV_GroupID)
{
	uint16_t4 v = uint16_t4(0, 0, 0, 0);

	[unroll]
	for (int i = 0; i < 64; i++)
	{
		Uint8 t = BAB.Load<Uint8>(2 * (thr + 32 * i));
		v += t.a;
		v += t.b;

		t = BAB.Load<Uint8>(2 * (gid.x + i));
		v += t.a;
		v += t.b;
	}

	RWTexBuf[gid.y].Store<uint16_t4>(8 * thr, v);
}

