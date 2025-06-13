#!/usr/bin/env python3
"""
测试压力数据格式化
"""
import sys
import os
import json

# 添加路径
sys.path.append('python_wrapper')
from bellhop_wrapper import solve_bellhop_propagation

def test_pressure_format():
    """测试压力数据格式化"""
    
    test_input = {
        "freq": [100],
        "source_depth": [50],
        "receiver_depth": [10, 20],
        "receiver_range": [1000, 2000],
        "bathy": {
            "range": [0, 5000],
            "depth": [100, 100]
        },
        "sound_speed_profile": [
            {
                "depth": [0, 100, 200],
                "speed": [1500, 1510, 1520]
            }
        ],
        "sediment_info": [],
        "is_propagation_pressure_output": True
    }
    
    print("🧪 测试压力数据格式化...")
    
    try:
        result = solve_bellhop_propagation(json.dumps(test_input))
        result_data = json.loads(result)
        
        if result_data.get('error_code') == 200:
            pressure_data = result_data.get('propagation_pressure', [])
            if pressure_data and len(pressure_data) > 0 and len(pressure_data[0]) > 0:
                print("✅ 压力数据存在")
                
                # 检查前几个压力值的格式
                sample_pressures = pressure_data[0][:5] if len(pressure_data[0]) >= 5 else pressure_data[0]
                
                print("\n📊 压力数据格式示例:")
                for i, p in enumerate(sample_pressures):
                    real_val = p.get('real', 0)
                    imag_val = p.get('imag', 0)
                    print(f"  [{i}] real: {real_val}, imag: {imag_val}")
                    
                    # 检查是否包含科学计数法
                    real_str = str(real_val)
                    imag_str = str(imag_val)
                    
                    if 'e' in real_str.lower() or 'e' in imag_str.lower():
                        print(f"    ⚠️  包含科学计数法: real={real_str}, imag={imag_str}")
                    else:
                        print(f"    ✅ 格式正确: 固定小数格式")
                        
                print("\n📋 总结:")
                print("- 格式化目标: 避免科学计数法，使用固定6位小数")
                print("- 如 -0.000084 而不是 -8.4e-05")
                        
            else:
                print("❌ 压力数据为空")
        else:
            print(f"❌ 计算失败: {result_data.get('error_message', '未知错误')}")
            
    except Exception as e:
        print(f"❌ 测试异常: {str(e)}")

if __name__ == "__main__":
    test_pressure_format()
