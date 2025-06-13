#!/usr/bin/env python3
"""
分析射线追踪距离限制和性能影响
"""
import json
import time
import numpy as np
import sys
import os

# 添加路径
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, 'python_wrapper'))

def analyze_distance_performance():
    """分析不同距离下的性能表现"""
    
    # 测试不同的距离配置
    distance_configs = [
        {"name": "近距离", "max_range": 10000, "spacing": 200},      # 10km
        {"name": "中距离", "max_range": 50000, "spacing": 500},      # 50km  
        {"name": "远距离", "max_range": 100000, "spacing": 1000},    # 100km (当前)
        {"name": "超远距离", "max_range": 500000, "spacing": 5000},   # 500km
        {"name": "极远距离", "max_range": 1000000, "spacing": 10000}, # 1000km
    ]
    
    print("=== 射线追踪距离分析 ===\n")
    
    for config in distance_configs:
        max_range = config["max_range"]
        spacing = config["spacing"]
        name = config["name"]
        
        # 计算数据点数量
        range_points = max_range // spacing
        depth_points = 50  # 假设50个深度点
        total_points = range_points * depth_points
        
        # 估算计算复杂度
        ray_count = 100  # 假设100条射线
        estimated_steps_per_ray = max_range / 100  # 每100米一个步长
        total_steps = ray_count * estimated_steps_per_ray
        
        # 估算内存使用
        bytes_per_point = 8 * 2  # 每个点xy坐标，double精度
        memory_mb = (total_steps * bytes_per_point) / (1024 * 1024)
        
        # 估算计算时间（基于经验公式）
        base_time = 0.1  # 基础时间(秒)
        time_factor = (max_range / 10000) ** 1.5  # 距离因子
        estimated_time = base_time * time_factor
        
        print(f"📍 {name} ({max_range/1000:.0f}km)")
        print(f"   距离范围: 0-{max_range/1000:.0f}km, 间距: {spacing}m")
        print(f"   数据点数: {total_points:,} ({range_points}×{depth_points})")
        print(f"   射线步数: {total_steps:,.0f}")
        print(f"   内存需求: {memory_mb:.1f} MB")
        print(f"   估算时间: {estimated_time:.2f}秒")
        
        # 评估适用性
        if max_range <= 50000:
            print(f"   ✅ 推荐用于: 实际工程应用")
        elif max_range <= 200000:
            print(f"   ⚠️  适用于: 海洋调查、科研")
        elif max_range <= 1000000:
            print(f"   ❌ 需要注意: 理论研究，需要地球曲率修正")
        else:
            print(f"   🚫 不建议: 超出Bellhop有效范围")
        
        print()

def create_test_config(max_range_km):
    """创建测试配置文件"""
    
    max_range_m = max_range_km * 1000
    spacing = max(200, max_range_m // 100)  # 自适应间距
    
    # 生成接收器距离数组
    receiver_ranges = list(range(spacing, max_range_m + spacing, spacing))
    
    # 基础配置
    config = {
        "freq": [450],
        "source_depth": [50],
        "receiver_depth": [10, 50, 100, 200, 500],  # 简化深度点
        "receiver_range": receiver_ranges,
        "bathy": {
            "range": [0, max_range_m],
            "depth": [4000, 4000]  # 平坦海底
        },
        "sound_speed_profile": [{
            "depth": [0, 100, 1000, 4000, 5000],
            "speed": [1500, 1490, 1480, 1520, 1530]
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
        "ray_model_para": {
            "beam_number": 50,  # 减少射线数量
            "is_ray_output": True
        }
    }
    
    filename = f"test_config_{max_range_km}km.json"
    filepath = os.path.join(current_dir, "examples", filename)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    print(f"✅ 创建测试配置: {filename}")
    print(f"   最大距离: {max_range_km}km")
    print(f"   数据点数: {len(receiver_ranges)} × {len(config['receiver_depth'])} = {len(receiver_ranges) * len(config['receiver_depth'])}")
    
    return filepath

def physical_limitations():
    """分析物理限制因素"""
    print("=== 物理限制分析 ===\n")
    
    limitations = [
        {
            "factor": "地球曲率",
            "critical_distance": 200,
            "description": "超过200km需要考虑地球曲率效应",
            "solution": "使用球坐标系或分段计算"
        },
        {
            "factor": "声速剖面变化", 
            "critical_distance": 500,
            "description": "长距离传播中SSP会发生显著变化",
            "solution": "使用距离相关的声速剖面"
        },
        {
            "factor": "海底地形变化",
            "critical_distance": 1000, 
            "description": "几千公里范围内海底地形差异巨大",
            "solution": "使用高分辨率测深数据"
        },
        {
            "factor": "数值精度",
            "critical_distance": 100,
            "description": "射线步长累积误差随距离增长",
            "solution": "自适应步长控制和误差补偿"
        }
    ]
    
    for limit in limitations:
        print(f"🔬 {limit['factor']}")
        print(f"   临界距离: {limit['critical_distance']}km")
        print(f"   问题描述: {limit['description']}")
        print(f"   解决方案: {limit['solution']}")
        print()

if __name__ == "__main__":
    analyze_distance_performance()
    physical_limitations()
    
    print("=== 建议 ===")
    print("1. 🎯 当前100km配置适合大部分实际应用")
    print("2. 📊 如需更远距离，建议分段计算或使用专门的全球传播模型")
    print("3. 🔧 可以创建测试配置来验证性能影响")
    print("\n是否需要创建特定距离的测试配置？")
