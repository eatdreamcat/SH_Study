using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SH : MonoBehaviour
{
    public Cubemap cubemap;
    
    public Cubemap writeMap;

    public Material material;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    
    public static float AreaElement(float x, float y)
    {
        return Mathf.Atan2(x * y, Mathf.Sqrt(x * x + y * y + 1));
    }

    public static float DifferentialSolidAngle(int textureSize, float U, float V)
    {
        float inv = 1.0f / textureSize;
        float u = 2.0f * (U + 0.5f * inv) - 1;
        float v = 2.0f * (V + 0.5f * inv) - 1;
        float x0 = u - inv;
        float y0 = v - inv;
        float x1 = u + inv;
        float y1 = v + inv;
        return AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
    }

    
    double sqrt(float num)
    {
        return Math.Sqrt(num);
    }
    
    double SHBasicFactor(int level)
    {
        switch (level)
        {
            // l = 0
            case 0:
                return 0.5f * sqrt(INV_PI);
            // l = 1
            case 1:
                return sqrt(3f / 4f * INV_PI);
            case 2:
                return sqrt(3f / 4f * INV_PI);
            case 3:
                return sqrt(3f / 4f * INV_PI);
            // l = 2
            case 4:
                return 0.5f * sqrt(15f * INV_PI);
            case 5:
                return 0.5f * sqrt(15f * INV_PI);
            case 6:
                return 0.25f * sqrt(5f * INV_PI);
            case 7:
                return 0.5f * sqrt(15f * INV_PI);
            case 8:
                return 0.25f * sqrt(15f * INV_PI);
            // l = 3
            case 9:
                return 0.25f * sqrt(35f / 2f * INV_PI);
            case 10:
                return 0.5f * sqrt(105f * INV_PI);
            case 11:
                return 0.25f * sqrt(21f / 2f * INV_PI);
            case 12:
                return 0.25f * sqrt(7f * INV_PI);
            case 13:
                return 0.25f * sqrt(21f / 2f * INV_PI);
            case 14:
                return 0.25f * sqrt(105f * INV_PI) ;
            case 15:
                return 0.25f * sqrt(35f / 2f * INV_PI);
            default:
                return 0f;
        }
    }
    
    
    
    private static readonly float INV_PI = 1 / 3.1416f;
    private static readonly float PI =  3.1416f;
    double SHBasic(Vector3 normal, int level)
    {
        normal.Normalize();
        float x = normal.x;
        float y = normal.y;
        float z = normal.z;
        switch (level)
        {
            // l = 0 
            case 0:
                return 0.5f * sqrt(INV_PI);
            // l = 1
            case 1:
                return sqrt(3f / 4f * INV_PI) * x;
            case 2:
                return sqrt(3f / 4f * INV_PI) * y;
            case 3:
                return sqrt(3f / 4f * INV_PI) * z;
            // l = 2
            case 4:
                return 0.5f * sqrt(15f * INV_PI) * x * y;
            case 5:
                return 0.5f * sqrt(15f * INV_PI) * z * y;
            case 6:
                return 0.25f * sqrt(5f * INV_PI) * (z * z * 3 - 1);
            case 7:
                return 0.5f * sqrt(15f * INV_PI) * z * x;
            case 8:
                return 0.25f * sqrt(15f * INV_PI) * (x * x - y * y);
            // l = 3
            case 9:
                return 0.25f * sqrt(35f / 2f * INV_PI) * (3 * x * x * y - y * y * y);
            case 10:
                return 0.5f * sqrt(105f * INV_PI) * x * y * z;
            case 11:
                return 0.25f * sqrt(21f / 2f * INV_PI) * (5 * z * z * y - y);
            case 12:
                return 0.25f * sqrt(7f * INV_PI) * 5 * z * z * z - 3 * z;
            case 13:
                return 0.25f * sqrt(21f / 2f * INV_PI) * (5 * z * z * x - x);
            case 14:
                return 0.25f * sqrt(105f * INV_PI) * (x * x * z - y * y * z);
            case 15:
                return 0.25f * sqrt(35f / 2f * INV_PI) * (x * x * x- 3 * y * y * x);
            default:
                return 0f;
        }
    }

    public void GenSH()
    {
        const int level = 3;
        const int step = 1;
        
        int size = cubemap.height;

        Debug.Log($"cubemap.height:{cubemap.height}");
        Vector4[] output = new Vector4[level * level];

        for(int i = 0; i < level * level; ++i)
        {
            output[i] = Vector4.zero;
        }

        var count = 0;
       
        for(int i = 0; i < 6; ++i)
        {
            var face = (CubemapFace)i;

            for(int y = 0; y < size; y += step)
            {
                for (int x = 0; x < size; x += step)
                {
                    count++;
                    // uv = xy / (size - 1)
                    var u = (float) (x) / (size - 1f);
                    var v = y / (size - 1f);
                    // 这里是前面说的UV转采样向量的方法
                    var dir = UVToDir(face, new Vector2(u, v));
                    dir.Normalize();
                    var radiance = cubemap.GetPixel(face, x, y);

                    for (int c = 0; c < level * level; ++c)
                    {
                        output[c].x += radiance.r * (float) SHBasic(dir, c);// * (float) SHBasicFactor(c);
                    
                    
                        output[c].y += radiance.g * (float) SHBasic(dir, c);// * (float) SHBasicFactor(c);
                    
                    
                        output[c].z += radiance.b * (float) SHBasic(dir, c);// * (float) SHBasicFactor(c);
                        
                    }
                    
                }
            }
        }
        
        Debug.Log($"采样数量：{count}");
        for(int i = 0; i < level * level; ++i)
        {
            output[i].x /= count;
            output[i].y /= count;
            output[i].z /= count;
            output[i].x *=  4*PI;
            output[i].y *=  4*PI;
            output[i].z *=  4*PI;
            output[i].x *= (float) SHBasicFactor(i);
            output[i].y *= (float) SHBasicFactor(i);
            output[i].z *= (float) SHBasicFactor(i);
            Debug.Log($"SH{i}r:{output[i].x}, SH{i}g:{output[i].y},SH{i}b:{output[i].z}");
        }
        
        this.material.SetVectorArray("_SHArray", output);
    }

    Vector3 UVToDir(CubemapFace face, Vector2 uv)
    {
        uv.x = 2 * uv.x - 1;
        uv.y = 2 * uv.y - 1;
        switch (face)
        {
            case CubemapFace.NegativeX:
                return new Vector3(-1, uv.y, uv.x);
            case CubemapFace.PositiveX:
                return new Vector3(1, uv.y, -uv.x);
            case CubemapFace.NegativeY:
                return new Vector3(uv.x, -1, uv.y);
            case CubemapFace.PositiveY:
                return new Vector3(uv.x, 1, -uv.y);
            case CubemapFace.NegativeZ:
                return new Vector3(-uv.x, uv.y, -1);
            case CubemapFace.PositiveZ:
                return new Vector3(uv.x, uv.y, 1);
            default:
                return Vector3.zero;
        }
    }
}
