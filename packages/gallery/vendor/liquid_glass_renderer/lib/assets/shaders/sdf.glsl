// Shape array uniforms - 6 floats per shape (type, centerX, centerY, sizeW, sizeH, cornerRadius)
// Reduced from 64 to 16 shapes to fit Impeller's uniform buffer limit (16 * 6 = 96 floats vs 384)
//
// IMPORTANT: Every shader that includes this file must declare a
// `uniform float uShapeData[MAX_SHAPES * 6];` *before* the include. The SDF
// helpers below read that global uniform directly instead of taking it as a
// function parameter on purpose: passing an array by value makes spirv-cross
// emit an array copy-initializer (`float param[96] = uShapeData;`) which is
// rejected by SkSL, so the shaders would fail to compile on the Skia backend.
#ifndef MAX_SHAPES
#define MAX_SHAPES 16
#endif

float sdfRRect( in vec2 p, in vec2 b, in float r ) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);
    vec2 q = abs(p)-b+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

float sdfRect(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdfSquircle(vec2 p, vec2 b, float r) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);

    vec2 q = abs(p) - b + r;
    
    vec2 maxQ = max(q, 0.0);
    return min(max(q.x, q.y), 0.0) + sqrt(maxQ.x * maxQ.x + maxQ.y * maxQ.y) - r;
}

float sdfEllipse(vec2 p, vec2 r) {
    r = max(r, 1e-4);
    
    vec2 invR = 1.0 / r;
    vec2 invR2 = invR * invR;
    
    vec2 pInvR = p * invR;
    float k1 = length(pInvR);
    
    vec2 pInvR2 = p * invR2;
    float k2 = length(pInvR2);
    
    return (k1 * (k1 - 1.0)) / max(k2, 1e-4);
}

float smoothUnion(float d1, float d2, float k) {
    if (k <= 0.0) {
        return min(d1, d2);
    }
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / k;
}

float getShapeSDF(float type, vec2 p, vec2 center, vec2 size, float r) {
    if (type == 1.0) { // squircle
        return sdfSquircle(p - center, size / 2.0, r);
    }
    if (type == 2.0) { // ellipse
        return sdfEllipse(p - center, size / 2.0);
    }
    if (type == 3.0) { // rounded rectangle
        return sdfRRect(p - center, size / 2.0, r);
    }
    return 1e9; // none
}

// Reads the globally declared `uShapeData` uniform directly (see note above).
float getShapeSDFFromArray(int index, vec2 p) {
    float type = 0.0;
    vec2 center = vec2(0.0);
    vec2 size = vec2(0.0);
    float cornerRadius = 0.0;

    switch (index) {
        case 0:
            type = uShapeData[0]; center = vec2(uShapeData[1], uShapeData[2]);
            size = vec2(uShapeData[3], uShapeData[4]); cornerRadius = uShapeData[5]; break;
        case 1:
            type = uShapeData[6]; center = vec2(uShapeData[7], uShapeData[8]);
            size = vec2(uShapeData[9], uShapeData[10]); cornerRadius = uShapeData[11]; break;
        case 2:
            type = uShapeData[12]; center = vec2(uShapeData[13], uShapeData[14]);
            size = vec2(uShapeData[15], uShapeData[16]); cornerRadius = uShapeData[17]; break;
        case 3:
            type = uShapeData[18]; center = vec2(uShapeData[19], uShapeData[20]);
            size = vec2(uShapeData[21], uShapeData[22]); cornerRadius = uShapeData[23]; break;
        case 4:
            type = uShapeData[24]; center = vec2(uShapeData[25], uShapeData[26]);
            size = vec2(uShapeData[27], uShapeData[28]); cornerRadius = uShapeData[29]; break;
        case 5:
            type = uShapeData[30]; center = vec2(uShapeData[31], uShapeData[32]);
            size = vec2(uShapeData[33], uShapeData[34]); cornerRadius = uShapeData[35]; break;
        case 6:
            type = uShapeData[36]; center = vec2(uShapeData[37], uShapeData[38]);
            size = vec2(uShapeData[39], uShapeData[40]); cornerRadius = uShapeData[41]; break;
        case 7:
            type = uShapeData[42]; center = vec2(uShapeData[43], uShapeData[44]);
            size = vec2(uShapeData[45], uShapeData[46]); cornerRadius = uShapeData[47]; break;
        case 8:
            type = uShapeData[48]; center = vec2(uShapeData[49], uShapeData[50]);
            size = vec2(uShapeData[51], uShapeData[52]); cornerRadius = uShapeData[53]; break;
        case 9:
            type = uShapeData[54]; center = vec2(uShapeData[55], uShapeData[56]);
            size = vec2(uShapeData[57], uShapeData[58]); cornerRadius = uShapeData[59]; break;
        case 10:
            type = uShapeData[60]; center = vec2(uShapeData[61], uShapeData[62]);
            size = vec2(uShapeData[63], uShapeData[64]); cornerRadius = uShapeData[65]; break;
        case 11:
            type = uShapeData[66]; center = vec2(uShapeData[67], uShapeData[68]);
            size = vec2(uShapeData[69], uShapeData[70]); cornerRadius = uShapeData[71]; break;
        case 12:
            type = uShapeData[72]; center = vec2(uShapeData[73], uShapeData[74]);
            size = vec2(uShapeData[75], uShapeData[76]); cornerRadius = uShapeData[77]; break;
        case 13:
            type = uShapeData[78]; center = vec2(uShapeData[79], uShapeData[80]);
            size = vec2(uShapeData[81], uShapeData[82]); cornerRadius = uShapeData[83]; break;
        case 14:
            type = uShapeData[84]; center = vec2(uShapeData[85], uShapeData[86]);
            size = vec2(uShapeData[87], uShapeData[88]); cornerRadius = uShapeData[89]; break;
        case 15:
            type = uShapeData[90]; center = vec2(uShapeData[91], uShapeData[92]);
            size = vec2(uShapeData[93], uShapeData[94]); cornerRadius = uShapeData[95]; break;
        default:
            return 1e9;
    }
    return getShapeSDF(type, p, center, size, cornerRadius);
}

float sceneSDF(vec2 p, int numShapes, float blend) {
    if (numShapes == 0) {
        return 1e9;
    }
    
    float result = getShapeSDFFromArray(0, p);
    
    // Optimized: unroll for common cases (1-4 shapes), use loop for 5+ shapes
    if (numShapes <= 4) {
        // Fully unrolled for 1-4 shapes (covers 90%+ of use cases)
        if (numShapes >= 2) {
            float shapeSDF = getShapeSDFFromArray(1, p);
            result = smoothUnion(result, shapeSDF, blend);
        }
        if (numShapes >= 3) {
            float shapeSDF = getShapeSDFFromArray(2, p);
            result = smoothUnion(result, shapeSDF, blend);
        }
        if (numShapes >= 4) {
            float shapeSDF = getShapeSDFFromArray(3, p);
            result = smoothUnion(result, shapeSDF, blend);
        }
    } else {
        // Dynamic loop for 5+ shapes (uncommon cases).
        // SkSL requires the loop bound to be a constant expression, so we
        // iterate up to the constant MAX_SHAPES and break once we run out of
        // real shapes. (SkSL also has no integer min() overload.)
        int shapeCount = numShapes < MAX_SHAPES ? numShapes : MAX_SHAPES;
        for (int i = 1; i < MAX_SHAPES; i++) {
            if (i >= shapeCount) {
                break;
            }
            float shapeSDF = getShapeSDFFromArray(i, p);
            result = smoothUnion(result, shapeSDF, blend);
        }
    }
    
    return result;
}

// Calculate 3D normal using finite differences
vec3 getNormal(vec2 p, float sd, float thickness, int numShapes, float blend) {
    float sd_x = sceneSDF(p + vec2(1.0, 0.0), numShapes, blend);
    float sd_y = sceneSDF(p + vec2(0.0, 1.0), numShapes, blend);
    float dx = sd_x - sd;
    float dy = sd_y - sd;
    
    // The cosine and sine between normal and the xy plane
    float n_cos = max(thickness + sd, 0.0) / thickness;
    float n_sin = sqrt(max(0.0, 1.0 - n_cos * n_cos));
    
    return normalize(vec3(dx * n_cos, dy * n_cos, n_sin));
}
