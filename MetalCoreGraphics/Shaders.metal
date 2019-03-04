//
//  Shaders.metal
//  MetalCoreGraphics
//
//  Created by Andrey Volodin on 04.03.2018.
//  Copyright © 2019 Andrey Volodin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MTLTextureViewVertexOut {
    float4 position [[ position ]];
    float2 uv;
};

vertex MTLTextureViewVertexOut vertexFunc(uint vid [[vertex_id]]) {
    MTLTextureViewVertexOut out;

    const float2 vertices[] = { float2(-1.0f, 1.0f), float2(-1.0f, -1.0f),
        float2(1.0f, 1.0f), float2(1.0f, -1.0f)
    };

    out.position = float4(vertices[vid], 0.0, 1.0);
    float2 uv = vertices[vid];
    uv.y = -uv.y;
    out.uv = fma(uv, 0.5f, 0.5f);

    return out;
}

fragment half4 fragmentFunc(MTLTextureViewVertexOut in [[stage_in]],
                            texture2d<half, access::sample> original [[texture(0)]],
                            texture2d<half, access::sample> blurred [[texture(1)]],
                            texture2d<half, access::sample> visibilityMask [[texture(2)]])
{
    constexpr sampler s(coord::normalized,
                        address::clamp_to_zero,
                        filter::linear);

    half4 originalColor = original.sample(s, in.uv);
    half4 blurredColor = blurred.sample(s, in.uv);
    half mask = visibilityMask.sample(s, in.uv).r;

    return mix(originalColor, blurredColor, 1.0 - mask);
}

