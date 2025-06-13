#!/usr/bin/env python3
"""
测试修复后的科学计数法问题
"""
import sys
import os

# 添加路径
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, 'python_wrapper'))

def test_fixed_scientific_notation():
    from bellhop_wrapper import solve_bellhop_propagation
    import json
    
    # 读取测试文件
    input_file = os.path.join(current_dir, 'examples', 'input_medium.json')
    with open(input_file, 'r') as f:
        input_data = json.load(f)
    
    # 添加压力输出选项
    input_data['is_propagation_pressure_output'] = True
    
    print("📊 正在测试修复后的科学计数法问题...")
    
    # 执行计算
    try:
        result_json = solve_bellhop_propagation(input_data)
        result = json.loads(result_json)
        
        # 检查压力数据
        if result.get('propagation_pressure'):
            print("✅ 发现压力数据，检查科学计数法...")
            
            # 检查前几个压力值
            pressure_data = result['propagation_pressure']
            sample_found = False
            
            for i, row in enumerate(pressure_data[:5]):  # 检查前5行
                if row:  # 如果行不为空
                    for j, pressure_val in enumerate(row[:5]):  # 检查前5列
                        real_val = pressure_val.get('real', '0')
                        imag_val = pressure_val.get('imag', '0')
                        
                        if not sample_found:
                            print(f"样本 [{i}][{j}]: real={real_val}, imag={imag_val}")
                            print(f"  real类型: {type(real_val)}")
                            print(f"  imag类型: {type(imag_val)}")
                            sample_found = True
                        
                        # 检查是否包含科学计数法
                        if isinstance(real_val, str):
                            if 'e-' in str(real_val) or 'e+' in str(real_val):
                                print(f"❌ 发现科学计数法 real: {real_val}")
                                return False
                        if isinstance(imag_val, str):
                            if 'e-' in str(imag_val) or 'e+' in str(imag_val):
                                print(f"❌ 发现科学计数法 imag: {imag_val}")
                                return False
            
            print("✅ 未发现科学计数法格式！")
            
            # 保存测试结果
            output_file = os.path.join(current_dir, 'examples', 'output_fixed_scientific.json')
            with open(output_file, 'w') as f:
                f.write(result_json)
            print(f"📁 结果已保存到: {output_file}")
            
            return True
        else:
            print("⚠️  没有压力数据")
            return False
            
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_fixed_scientific_notation()
    if success:
        print("\n🎉 科学计数法问题已修复！")
    else:
        print("\n😞 修复未成功，需要进一步调试")
