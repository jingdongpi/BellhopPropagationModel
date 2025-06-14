#!/usr/bin/env python3
"""
简单的日志控制模块
用于控制 Bellhop 模块的输出级别
"""

import os

# 日志级别控制
# 0: 静默模式 (只输出错误)
# 1: 基本信息 (关键操作信息)  
# 2: 详细模式 (所有调试信息)
LOG_LEVEL = int(os.environ.get('BELLHOP_LOG_LEVEL', '0'))

def log_info(message):
    """输出基本信息 (LOG_LEVEL >= 1)"""
    if LOG_LEVEL >= 1:
        print(message)

def log_debug(message):
    """输出调试信息 (LOG_LEVEL >= 2)"""
    if LOG_LEVEL >= 2:
        print(message)

def log_error(message):
    """输出错误信息 (总是输出)"""
    print(f"Error: {message}")

def log_warning(message):
    """输出警告信息 (LOG_LEVEL >= 1)"""
    if LOG_LEVEL >= 1:
        print(f"Warning: {message}")
