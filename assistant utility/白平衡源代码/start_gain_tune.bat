@echo off
chcp 65001 >nul
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
    echo 未找到 python，请先安装 Python 3 并勾选 Add to PATH
    pause
    exit /b 1
)

python -c "import PyQt5" 2>nul
if errorlevel 1 (
    python -c "import PyQt6" 2>nul
    if errorlevel 1 (
        echo 正在安装 PyQt5 ...
        python -m pip install PyQt5
        if errorlevel 1 (
            echo PyQt5 安装失败
            pause
            exit /b 1
        )
    )
)

python "%~dp0gain_tune.py"
if errorlevel 1 pause
