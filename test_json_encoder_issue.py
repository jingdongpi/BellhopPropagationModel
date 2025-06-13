#!/usr/bin/env python3
"""
测试JSONEncoder处理字符串数值的问题
"""
import json

class NoScientificJSONEncoder(json.JSONEncoder):
    def encode(self, obj):
        if isinstance(obj, float):
            # 对于浮点数，强制使用固定小数点格式
            if abs(obj) < 1e-10:  # 极小值设为0
                return "0.000000"
            elif abs(obj) >= 1e6:  # 极大值保持原样
                return str(obj)
            else:
                # 根据数值大小决定小数位数
                if abs(obj) >= 1:
                    return f"{obj:.2f}"
                else:
                    return f"{obj:.6f}"
        return super().encode(obj)
    
    def iterencode(self, obj, _one_shot=False):
        """递归处理所有浮点数"""
        if isinstance(obj, float):
            yield self.encode(obj)
        elif isinstance(obj, str):
            # 对于字符串，直接输出数值（用于压力数据）
            try:
                # 检查是否为数值字符串
                float(obj)
                yield obj  # 这里有问题！字符串需要加引号
            except ValueError:
                # 如果不是数值字符串，按普通字符串处理
                yield json.dumps(obj)
        elif isinstance(obj, dict):
            yield '{'
            first = True
            for key, value in obj.items():
                if not first:
                    yield ', '
                first = False
                yield json.dumps(key)
                yield ': '
                yield from self.iterencode(value)
            yield '}'
        elif isinstance(obj, list):
            yield '['
            first = True
            for item in obj:
                if not first:
                    yield ', '
                first = False
                yield from self.iterencode(item)
            yield ']'
        else:
            yield json.dumps(obj)

def test_json_encoder_problem():
    """测试当前JSONEncoder的问题"""
    
    # 模拟round_to_6_decimals函数返回的字符串
    def round_to_6_decimals(value):
        return f"{float(value):.6f}"
    
    # 测试数据
    test_data = {
        "real": round_to_6_decimals(-1.4e-05),  # 返回字符串 "-0.000014"
        "imag": round_to_6_decimals(5.2e-05),   # 返回字符串 "0.000052"
        "normal_float": -1.4e-05,               # 普通浮点数
        "normal_string": "hello"                # 普通字符串
    }
    
    print("=== 测试数据类型 ===")
    for key, value in test_data.items():
        print(f"{key}: {value} (type: {type(value)})")
    
    print("\n=== 使用当前JSONEncoder ===")
    try:
        result = json.dumps(test_data, cls=NoScientificJSONEncoder)
        print("结果:", result)
    except Exception as e:
        print("错误:", e)
    
    print("\n=== 分析问题 ===")
    print("问题：字符串数值需要保持为数值，而不是带引号的字符串")
    print("解决方案：修改iterencode方法，对数值字符串特殊处理")

if __name__ == "__main__":
    test_json_encoder_problem()
