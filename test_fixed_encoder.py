#!/usr/bin/env python3
"""
测试修复后的JSONEncoder
"""
import sys
sys.path.insert(0, '/home/shunli/AcousticProjects/BellhopPropagationModel/python_wrapper')

from bellhop_wrapper import solve_bellhop_propagation
import json

def test_fixed_encoder():
    """测试修复后的编码器"""
    
    # 创建一个小的测试输入
    test_input = {
        "freq": [450],
        "source_depth": [50],
        "receiver_depth": [0.1, 10.0],
        "receiver_range": [500, 1000],
        "bathy": {
            "range": [0, 2000],
            "depth": [100, 100]
        },
        "sound_speed_profile": [{
            "depth": [0, 50, 100, 150],
            "speed": [1500, 1490, 1480, 1470]
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
        "is_propagation_pressure_output": True,
        "ray_model_para": {
            "beam_number": 10,
            "is_ray_output": True
        }
    }
    
    print("=== 测试修复后的JSONEncoder ===")
    print("输入数据:", json.dumps(test_input, indent=2))
    
    # 调用bellhop计算
    result_json = solve_bellhop_propagation(json.dumps(test_input))
    result = json.loads(result_json)
    
    print("\n计算结果:")
    print(f"错误代码: {result.get('error_code')}")
    print(f"错误信息: {result.get('error_message')}")
    
    # 检查压力数据中是否还有科学计数法
    pressure_data = result.get('propagation_pressure', [])
    if pressure_data:
        print(f"\n压力数据维度: {len(pressure_data)} x {len(pressure_data[0]) if pressure_data else 0}")
        
        # 检查前几个压力值
        print("前几个压力值:")
        count = 0
        for i, row in enumerate(pressure_data[:3]):
            if not row:
                continue
            for j, pressure_point in enumerate(row[:3]):
                if isinstance(pressure_point, dict):
                    real = pressure_point.get('real')
                    imag = pressure_point.get('imag')
                    print(f"  [{i}][{j}]: real={real} (type:{type(real)}), imag={imag} (type:{type(imag)})")
                    count += 1
                    if count >= 6:
                        break
            if count >= 6:
                break
        
        # 检查是否有科学计数法
        has_scientific = False
        for row in pressure_data:
            if not row:
                continue
            for pressure_point in row:
                if isinstance(pressure_point, dict):
                    for key, value in pressure_point.items():
                        if isinstance(value, str) and ('e-' in value or 'e+' in value):
                            print(f"⚠️ 发现科学计数法: {key}={value}")
                            has_scientific = True
        
        if not has_scientific:
            print("✅ 压力数据中无科学计数法!")
        else:
            print("❌ 压力数据中仍有科学计数法")
    
    # 保存测试结果
    output_file = "/home/shunli/AcousticProjects/BellhopPropagationModel/examples/test_fixed_encoder_output.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(result_json)
    
    print(f"\n测试结果已保存到: {output_file}")

if __name__ == "__main__":
    test_fixed_encoder()
