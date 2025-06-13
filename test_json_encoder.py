#!/usr/bin/env python3
"""
测试JSON编码器效果
"""
import json

def test_json_encoder():
    # 测试数据
    test_data = {
        "real": -1.4e-05,
        "imag": 5.2e-05
    }
    
    print("原始数据:", test_data)
    
    # 默认JSON编码
    default_json = json.dumps(test_data)
    print("默认JSON:", default_json)
    
    # 自定义编码器
    class NoScientificEncoder(json.JSONEncoder):
        def encode(self, obj):
            if isinstance(obj, float):
                return f'"{obj:.6f}"'
            return super().encode(obj)
            
        def iterencode(self, obj, _one_shot=False):
            if isinstance(obj, float):
                yield f'"{obj:.6f}"'
            elif isinstance(obj, dict):
                yield '{'
                first = True
                for key, value in obj.items():
                    if not first:
                        yield ', '
                    first = False
                    yield json.dumps(key) + ': '
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
    
    custom_json = json.dumps(test_data, cls=NoScientificEncoder)
    print("自定义JSON:", custom_json)
    
    # 使用字符串替换方法
    formatted_data = {}
    for key, value in test_data.items():
        if isinstance(value, float):
            formatted_data[key] = f"{value:.6f}"
        else:
            formatted_data[key] = value
    
    string_method_json = json.dumps(formatted_data)
    print("字符串方法:", string_method_json)

if __name__ == "__main__":
    test_json_encoder()
