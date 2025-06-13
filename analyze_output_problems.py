#!/usr/bin/env python3
"""
全面分析Bellhop输出中的问题并提供解决方案
"""
import json
import numpy as np
import os
import sys

def analyze_output_problems(output_file):
    """分析输出文件中的问题"""
    print("=== Bellhop输出问题分析 ===\n")
    
    with open(output_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 问题1: 科学计数法分析
    print("🔬 问题1: 科学计数法问题")
    analyze_scientific_notation(data)
    print()
    
    # 问题2: 传输损失250分析
    print("📊 问题2: 传输损失250dB问题")
    analyze_transmission_loss_250(data)
    print()
    
    # 问题3: 射线角度跳跃分析
    print("🎯 问题3: 射线角度跳跃问题")
    analyze_ray_angle_jumps(data)
    print()

def analyze_scientific_notation(data):
    """分析科学计数法问题"""
    pressure_data = data.get('propagation_pressure', [])
    
    scientific_count = 0
    total_pressure_values = 0
    
    for depth_row in pressure_data:
        if not depth_row:  # 跳过空行
            continue
        for pressure_point in depth_row:
            if isinstance(pressure_point, dict):
                for key, value in pressure_point.items():
                    if isinstance(value, str):
                        total_pressure_values += 1
                        if 'e-0' in value or 'e+0' in value or 'e-' in value or 'e+' in value:
                            scientific_count += 1
                    elif isinstance(value, float):
                        total_pressure_values += 1
                        # 检查浮点数是否会被序列化为科学计数法
                        if abs(value) < 1e-4 and value != 0:
                            scientific_count += 1
    
    print(f"   科学计数法数量: {scientific_count}/{total_pressure_values}")
    print(f"   问题比例: {scientific_count/total_pressure_values*100:.1f}%")
    
    if scientific_count > 0:
        print("   ❌ 仍存在科学计数法问题")
        print("   💡 解决方案:")
        print("      1. 检查round_to_6_decimals函数是否正确调用")
        print("      2. 确保所有压力数据都经过格式化")
        print("      3. 重新生成输出文件")
    else:
        print("   ✅ 无科学计数法问题")

def analyze_transmission_loss_250(data):
    """分析传输损失250dB问题"""
    tl_data = data.get('transmission_loss', [])
    
    if not tl_data:
        print("   ⚠️  无传输损失数据")
        return
    
    # 将多维数据扁平化
    flat_tl = []
    def flatten_tl(arr):
        for item in arr:
            if isinstance(item, list):
                flatten_tl(item)
            else:
                flat_tl.append(item)
    
    flatten_tl(tl_data)
    
    if not flat_tl:
        print("   ⚠️  传输损失数据为空")
        return
    
    tl_array = np.array(flat_tl)
    
    # 统计250dB的数量
    count_250 = np.sum(tl_array == 250.0)
    total_count = len(tl_array)
    
    print(f"   传输损失数据点总数: {total_count}")
    print(f"   250dB数据点数量: {count_250}")
    print(f"   250dB比例: {count_250/total_count*100:.1f}%")
    print(f"   传输损失范围: {np.min(tl_array):.1f} - {np.max(tl_array):.1f} dB")
    
    if count_250 > total_count * 0.1:  # 如果超过10%是250dB
        print("   ❌ 大量250dB值，可能表示:")
        print("      1. 声影区域 (Bellhop无法计算的区域)")
        print("      2. 计算参数设置不当")
        print("      3. 射线数量不足")
        print("   💡 解决方案:")
        print("      1. 增加射线数量 (beam_number)")
        print("      2. 调整角度范围")
        print("      3. 检查声速剖面和海底参数")
        print("      4. 使用更适合的传播模式")
    else:
        print("   ✅ 250dB值在合理范围内")

def analyze_ray_angle_jumps(data):
    """分析射线角度跳跃问题"""
    ray_data = data.get('ray_trace', [])
    
    if not ray_data:
        print("   ⚠️  无射线追踪数据")
        return
    
    print(f"   射线总数: {len(ray_data)}")
    
    # 分析角度分布
    angles = []
    angle_changes = []
    
    for i, ray in enumerate(ray_data):
        if isinstance(ray, dict) and 'alpha' in ray:
            angle = ray['alpha']
            angles.append(angle)
            
            if i > 0 and len(angles) > 1:
                change = abs(angle - angles[-2])
                angle_changes.append(change)
    
    if not angles:
        print("   ⚠️  无有效角度数据")
        return
    
    angles = np.array(angles)
    
    print(f"   角度范围: {np.min(angles):.1f}° - {np.max(angles):.1f}°")
    
    # 检查角度重复模式
    unique_angles, counts = np.unique(angles, return_counts=True)
    repeated_angles = unique_angles[counts > 1]
    
    print(f"   独特角度数: {len(unique_angles)}")
    print(f"   重复角度数: {len(repeated_angles)}")
    
    # 检查连续相同角度
    consecutive_same = 0
    current_streak = 1
    max_streak = 1
    
    for i in range(1, len(angles)):
        if angles[i] == angles[i-1]:
            current_streak += 1
            max_streak = max(max_streak, current_streak)
        else:
            if current_streak >= 3:
                consecutive_same += 1
            current_streak = 1
    
    print(f"   最大连续相同角度: {max_streak}")
    print(f"   3次或以上连续相同的组数: {consecutive_same}")
    
    if max_streak >= 3:
        print("   ❌ 发现连续相同角度问题")
        print("   💡 可能原因:")
        print("      1. 射线计算精度问题")
        print("      2. 角度步长设置不当")
        print("      3. 数值计算收敛问题")
        print("   💡 解决方案:")
        print("      1. 调整beam_number参数")
        print("      2. 修改角度范围设置")
        print("      3. 检查计算精度参数")
        print("      4. 使用不同的射线追踪算法")
    else:
        print("   ✅ 角度变化正常")
    
    # 分析射线轨迹长度
    if ray_data and isinstance(ray_data[0], dict):
        ray_lengths = []
        for ray in ray_data:
            if 'ray_range' in ray and ray['ray_range']:
                ray_lengths.append(len(ray['ray_range']))
        
        if ray_lengths:
            print(f"   射线轨迹点数范围: {min(ray_lengths)} - {max(ray_lengths)}")
            print(f"   平均轨迹点数: {np.mean(ray_lengths):.1f}")

def create_fix_script():
    """创建修复脚本"""
    fix_script = """#!/usr/bin/env python3
\"\"\"
修复Bellhop输出问题的脚本
\"\"\"
import json
import re

def fix_scientific_notation_in_file(input_file, output_file):
    \"\"\"修复文件中的科学计数法\"\"\"
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 使用正则表达式替换科学计数法
    def replace_scientific(match):
        value = float(match.group(0))
        return f'"{value:.6f}"'
    
    # 匹配科学计数法模式
    pattern = r'-?\\d+\\.?\\d*e[+-]\\d+'
    fixed_content = re.sub(pattern, replace_scientific, content)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"科学计数法修复完成: {input_file} -> {output_file}")

def regenerate_output_with_fixes():
    \"\"\"重新生成输出文件并应用所有修复\"\"\"
    import sys
    import os
    
    # 添加路径
    sys.path.insert(0, '/home/shunli/AcousticProjects/BellhopPropagationModel/python_wrapper')
    
    from bellhop_wrapper import solve_bellhop_propagation
    
    input_files = [
        '/home/shunli/AcousticProjects/BellhopPropagationModel/examples/input_medium.json'
    ]
    
    for input_file in input_files:
        if os.path.exists(input_file):
            with open(input_file, 'r', encoding='utf-8') as f:
                input_data = f.read()
            
            # 重新计算
            result = solve_bellhop_propagation(input_data)
            
            # 保存修复后的结果
            base_name = os.path.splitext(os.path.basename(input_file))[0]
            output_file = f'/home/shunli/AcousticProjects/BellhopPropagationModel/examples/output_{base_name}_fixed.json'
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(result)
            
            print(f"重新生成: {output_file}")

if __name__ == "__main__":
    regenerate_output_with_fixes()
"""
    
    with open('/home/shunli/AcousticProjects/BellhopPropagationModel/fix_output_problems.py', 'w', encoding='utf-8') as f:
        f.write(fix_script)
    
    print("💾 已创建修复脚本: fix_output_problems.py")

def main():
    output_file = '/home/shunli/AcousticProjects/BellhopPropagationModel/examples/output_input_medium_fixed.json'
    
    if not os.path.exists(output_file):
        print(f"❌ 文件不存在: {output_file}")
        return
    
    analyze_output_problems(output_file)
    
    print("=" * 60)
    print("📋 总结建议")
    print("=" * 60)
    
    print("1. 🔧 科学计数法修复:")
    print("   - 确保bellhop_wrapper.py中的round_to_6_decimals函数返回字符串")
    print("   - 重新生成所有输出文件")
    print()
    
    print("2. 📊 传输损失250dB问题:")
    print("   - 增加射线数量 (beam_number: 50 -> 100+)")
    print("   - 调整角度范围")
    print("   - 检查声速剖面参数")
    print()
    
    print("3. 🎯 射线角度跳跃问题:")
    print("   - 可能是正常的物理现象")
    print("   - 也可能需要调整计算参数")
    print("   - 建议与理论预期对比")
    print()
    
    create_fix_script()

if __name__ == "__main__":
    main()
