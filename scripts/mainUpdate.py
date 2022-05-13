# -*- coding:utf-8 -*-
import re
import sys
import requests
import subprocess
import os
import shutil
import json
from libs.masar import extract_asar, pack_asar
import zipfile
import time

# fix unicode character display error
sys.stdin.reconfigure(encoding='utf-8')
sys.stdout.reconfigure(encoding='utf-8')


def set_output(name, value):
    print(f"::set-output name={name}::{value}")


rootPath = os.path.dirname(__file__)

# https://ty\u0070ora-download.oss-cn-shanghai.aliyuncs.com"
# IMAGE_URL = "https://download.ty\u0070ora.io"


RETRIEVE_DIR = os.path.join(rootPath, "packages")
os.makedirs(RETRIEVE_DIR, exist_ok=True)


# 返回：下载链接，空字符串表示无更新
def isLatestVersion(isDev: bool = True) -> str:
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36'
    }
    response = requests.get(
        'https://api.github.com/repos/taozhiyu/TyProAction/tags', headers=headers).text
    resp = json.loads(requests.get(
        f'https://ty\u0070ora.io/releases/{"dev_" if isDev else ""}windows_64.json', headers=headers).text)
    latestVersion = resp["version"]
    print(latestVersion)
    set_output("update_url", f"update to {latestVersion}")
    return "" if latestVersion in response else resp["download"]


def downloadFile(url, filename):
    r = requests.get(url)
    with open(filename, "wb") as f:
        f.write(r.content)


def buildTyPro(version: str):
    rawAsarFile = os.path.join(RETRIEVE_DIR, version, "resources/app.asar")
    outPutPath = os.path.join(rootPath, f"output/{time.time_ns()}")
    decPath = os.path.join(outPutPath, "dec")

    if os.path.exists(decPath):
        shutil.rmtree(decPath)
    os.makedirs(decPath)
    # 解包asar
    extract_asar(rawAsarFile, decPath)
    # 修改入口
    with open(os.path.join(decPath, "package.json"), "r+", encoding="utf8") as f:
        package = json.loads(f.read())
        package["main"] = "duuump.js"
        f.seek(0)
        f.write(json.dumps(package, indent=4))
    # 复制js
    shutil.copyfile(os.path.join(rootPath, "libs/duuump.js"),
                    os.path.join(decPath, "duuump.js"))
    # 修补.node
    with open(os.path.join(decPath, "main.node"), "rb+") as f:
        node = f.read()

        pt = node.find(bytes.fromhex("48 89 84 24 A8 00 00 00"))
        print(pt)
        ba = bytearray(node)
        for i in range(5):
            ba[pt + i + 18] = 0x90

        pt = node.find(bytes.fromhex("4C 8D 4C 24 30 4D 8B C4"))
        print(pt)
        for i in range(6):
            ba[pt - i - 1] = 0x90

        pt = node.find(bytes.fromhex("B9 80 00 00 00 E8"))
        print(pt)
        for i in range(6):
            ba[pt - i - 1] = 0x90
        f.seek(0)
        f.write(ba)
    # 打包asar
    outPutAsar = os.path.join(outPutPath, "app.asar")
    pack_asar(decPath, outPutAsar)
    print("asar打包完成")
    # 压缩asar
    zipFile = os.path.join(rootPath, f'../asar-file-V{version}.zip')
    with zipfile.ZipFile(zipFile, 'w', zipfile.ZIP_DEFLATED) as f:
        f.write(outPutAsar, "./app.asar")
    print('zip path:', zipFile)
    # 复制回安装文件夹
    shutil.copyfile(outPutAsar, rawAsarFile)
    shutil.copyfile(os.path.join(decPath, "main.node"), os.path.join(
        os.path.dirname(rawAsarFile), "app.asar.unpacked/main.node"))
    # 打包
    PackTOOL = os.path.join(rootPath, "libs/compiler/ISCC.exe")
    with open(os.path.join(os.path.dirname(PackTOOL), "typro.iss"), "r+", encoding='gbk') as f:
        code = f.read()
        regex = r"MyAppVersion \"([\d\.]{3,}(-dev)?)\""
        result = re.sub(regex, "MyAppVersion \""+version +
                        "\"", code, 0, re.MULTILINE)
        # regex = r"packages\\([\d\.]{3,}(-dev)?)"
        # result = re.sub(regex, r"packages\\"+version, result, 0, re.MULTILINE)
        f.seek(0)
        f.truncate()
        f.write(result)
    print("开始打包（静默打包，提速1/6）")

    subprocess.check_call([PackTOOL, os.path.join(
        os.path.dirname(PackTOOL), "typro.iss"), "-Q"], cwd=rootPath)
    print("exe打包完成")
    # 分发(action实现)

    # 删除垃圾
    shutil.rmtree(RETRIEVE_DIR)
    shutil.rmtree(os.path.join(rootPath, "output"))
    print("垃圾删除完成")


def download_windows(downloadLink: str):
    # url = IMAGE_URL + f"/windows/ty\u0070ora-setup-x64-{version}.exe"
    fileName = os.path.basename(downloadLink).replace(".exe", "")
    version = re.search(r"([\d.]{3,}(-dev)?)", fileName).groups(1)[0]
    filePath = os.path.join(RETRIEVE_DIR, os.path.basename(downloadLink))
    if not os.path.exists(filePath):
        print(f"下载 {fileName}")
        downloadFile(downloadLink, filePath)
        print(f"{fileName} 下载完成")
    else:
        print("使用缓存exe")
    if not os.path.exists(os.path.join(RETRIEVE_DIR, version)):
        print("开始解包（静默打包，提速1/6）")
        extractTOOL = os.path.join(rootPath, "libs/innoextract.exe")
        subprocess.check_call(
            [extractTOOL, fileName + ".exe", "-s"], cwd=RETRIEVE_DIR)
        os.rename(os.path.join(RETRIEVE_DIR, "app"),
                  os.path.join(RETRIEVE_DIR, version))
        print("解包完成")
    else:
        print("使用缓存文件夹")
    set_output("update_version", version)
    try:
        buildTyPro(version)
    except BaseException as e:
        print('error 可能是解密错误')
        print(e)
        raise '解密错误'


if __name__ == '__main__':
    isDev = sys.argv[1] == "dev"
    print(f"当前检测：{'测试' if isDev else '稳定'}版")
    if len(sys.argv) > 2:
        v = sys.argv[2]
        print(f"当前手动触发版本号：{v}\n版本为{'测试' if 'dev' in v else '稳定'}版")
        v = f"https://typora-download.oss-cn-shanghai.aliyuncs.com/windows/typora-update-x64-{v}.exe"
        set_output("update_url", f"Manually triggered V{v}")
    else:
        v = isLatestVersion(isDev)
    if len(v) > 0:
        if isDev and ('dev' in v):
            print("更新")
            download_windows(v)
        else:
            set_output("update_url", "")
            print("非指定版本模式，跳过")
    else:
        set_output("update_url", "")
        print("无需更新")
