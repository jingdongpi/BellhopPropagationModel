#!/usr/bin/env python3
"""
测试科学计数法修复效果
"""
import json
import numpy as np
import sys
import os

# 添加路径
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, 'python_wrapper'))

def test_scientific_notation_fix():
    """测试科学计数法修复"""
    
    # 导入修复后的模块
    from bellhop_wrapper import solve_bellhop_propagation
    
    # 使用小数据集进行快速测试
    test_input = {
        "freq": [450],
        "source_depth": [50],
        "receiver_depth": [10, 50, 100],
        "receiver_range": [1000, 2000, 3000],
        "bathy": {
            "range": [0, 5000],
            "depth": [4000, 4000]
        },
        "sound_speed_profile": [{
            "depth": [0, 100, 1000, 4000],
            "speed": [1500, 1490, 1480, 1520]
        }],
        "sediment_info": [{
            "sediment": {
                "density": 1.8,
                "p_speed": 1600,
                "p_atten": 0.5,
                "s_speed": 0,
                "s_atten": 0.1
            }
        }],
        "is_propagation_pressure_output": True,  # 启用压力输出
        "ray_model_para": {
            "beam_number": 20,
            "is_ray_output": False  # 先不测试射线，只测试压力数据
        }
    }
    
    print("🧪 测试科学计数法修复...")
    print("📊 输入配置:")
    print(f"   频率: {test_input['freq'][0]} Hz")
    print(f"   深度点数: {len(test_input['receiver_depth'])}")
    print(f"   距离点数: {len(test_input['receiver_range'])}")
    print(f"   启用压力输出: {test_input['is_propagation_pressure_output']}")
    
    try:
        # 调用计算
        result_json = solve_bellhop_propagation(test_input)
        result = json.loads(result_json)
        
        print("\n✅ 计算完成")
        print(f"错误代码: {result.get('error_code', 'N/A')}")
        
        # 检查压力数据
        pressure_data = result.get('propagation_pressure', [])
        if pressure_data:
            print(f"\n📈 压力数据检查:")
            print(f"   数据维度: {len(pressure_data)} × {len(pressure_data[0]) if pressure_data else 0}")
            
            # 检查前几个数据点的格式
            sample_count = 0
            scientific_notation_found = False
            
            for i, row in enumerate(pressure_data[:3]):  # 只检查前3行
                for j, point in enumerate(row[:3]):  # 只检查前3列
                    real_val = point.get('real', 0)
                    imag_val = point.get('imag', 0)
                    
                    # 检查是否还有科学计数法
                    real_str = str(real_val)
                    imag_str = str(imag_val)
                    
                    if 'e' in real_str.lower() or 'e' in imag_str.lower():
                        scientific_notation_found = True
                        print(f"   ❌ 发现科学计数法 [{i},{j}]: real={real_str}, imag={imag_str}")
                    else:
                        print(f"   ✅ 格式正确 [{i},{j}]: real={real_str}, imag={imag_str}")
                    
                    sample_count += 1
                    if sample_count >= 5:  # 只检查前5个点
                        break
                if sample_count >= 5:
                    break
            
            if not scientific_notation_found:
                print(f"\n🎉 科学计数法修复成功！")
            else:
                print(f"\n⚠️  仍有科学计数法问题需要进一步修复")
                
        else:
            print("⚠️  没有压力数据输出")
            
        # 检查传输损失数据
        tl_data = result.get('transmission_loss', [])
        if tl_data:
            print(f"\n📊 传输损失数据:")
            print(f"   数据维度: {len(tl_data)} × {len(tl_data[0]) if tl_data else 0}")
            # 随机检查几个传输损失值
            if len(tl_data) > 0 and len(tl_data[0]) > 0:
                sample_tl = tl_data[0][0]
                print(f"   示例值: {sample_tl}")
                
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_scientific_notation_fix()
