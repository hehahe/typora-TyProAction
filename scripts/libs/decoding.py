# -*- coding:utf-8 -*-
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
from base64 import b64decode, b64encode
from os import listdir, makedirs
from os.path import isfile, isdir, join as pjoin, split as psplit, exists
from .masar import extract_asar, pack_asar
from shutil import rmtree
from argparse import ArgumentParser
import os
import struct

AES_KEY = b""
AES_IV = b""


def aesInit(asarPath: str):
    global AES_IV, AES_KEY
    with open(asarPath, "rb") as f:
        node = f.read()
        # keyPointer = node.find(b'\xC7\x85\xD0\x01\x00\x00')
        findPointer = []
        for i in range(100):
            if 4 * i > 0xff:
                break
            pt = node.find(bytes.fromhex(
                f"C785{f'{hex(4 * i)}'.replace('x', '')[-2:]}010000"))
            if pt > 0:
                findPointer.append(pt)

        successPointerNumber = 0
        keyPointer = 0
        for x in findPointer:
            if successPointerNumber == 7:
                keyPointer = x - 70
            if (x + 10) in findPointer:
                successPointerNumber += 1
        print(keyPointer)
        iv = []
        bitPointer = 8 if node[keyPointer - 8] == 65 else 7
        for p in range(4):
            pointer = keyPointer - (3 - p) * bitPointer - 1
            temp = '0x'
            for x in range(4):
                temp += (hex(node[pointer - x])).replace('x', '')[-2:]
            iv.append(int(temp, 16))
        tempKey = []
        for p in range(8):
            pointer = keyPointer + 6 + 10 * p
            temp = ''
            for x in range(4):
                temp = (hex(node[pointer + x])).replace('x', '')[-2:] + temp
            tempKey.append(temp)
        key = []
        for t in range(4):
            key.append(int("0x" + tempKey[t * 2 + 1] + tempKey[t * 2], 16))

        AES_KEY = struct.pack("<4Q", *key)
        AES_IV = struct.pack("<4L", *iv)


def decScript(b64: bytes):
    lCode = b64decode(b64)
    # iv
    aesIv = AES_IV
    # cipher text
    cipherText = lCode[:]
    # AES 256 CBC
    ins = AES.new(key=AES_KEY, iv=aesIv, mode=AES.MODE_CBC)
    code = unpad(ins.decrypt(cipherText), 16, 'pkcs7')
    return code


def extractWdec(asarPath, path):
    """
    :param asarPath: asar out dir
    :param path: out dir
    :return: None
    """
    aesInit(os.path.join(os.path.dirname(asarPath), "app.asar.unpacked/main.node"))

    # try to create empty dir to save extract files
    path = pjoin(path, "temp")

    if exists(path):
        rmtree(path)
    makedirs(path)

    print(f"extract asar file: {asarPath}")
    # extract app.asar to {path}/*
    extract_asar(asarPath, path)
    print(f"extract ended.")

    print(f"read Directory: {path}")
    # construct the save directory {pathRoot}/dec_app
    outPath = pjoin(psplit(path)[0], "dec_app")
    # try to create empty dir to save decryption files
    if exists(outPath):
        rmtree(outPath)
    makedirs(outPath)

    print(f"set Directory: {outPath}")
    # enumerate extract files
    fileArr = listdir(path)
    for name in fileArr:
        # read files content
        fpath = pjoin(path, name)
        scode = open(fpath, "rb").read()
        print(f"open file: {name}")
        # if file suffix is *.js then decryption file
        if isfile(fpath) and name.endswith(".js"):
            scode = decScript(scode)
        else:
            print(f"skip file: {name}")
        # save content {outPath}/{name}
        open(pjoin(outPath, name), "wb").write(scode)
        print(f"decrypt and save file: {name}")

    rmtree(path)
    print("remove temp dir")


def encScript(_code: bytes):
    aesIv = AES_IV
    cipherText = _code
    ins = AES.new(key=AES_KEY, iv=aesIv, mode=AES.MODE_CBC)
    enc = ins.encrypt(pad(cipherText, 16, 'pkcs7'))
    lCode = b64encode(enc)
    return lCode


def packWenc(path, outPath):
    """
    :param path: out dir
    :param outPath: pack path app.asar
    :return: None
    """
    aesInit(os.path.join(path, "main.node"))

    # check out path
    if isfile(outPath):
        print("plz input Directory for app.asar")
        raise NotADirectoryError

    if not exists(outPath):
        makedirs(outPath)

    encFilePath = pjoin(psplit(outPath)[0], "temp")
    if exists(encFilePath):
        rmtree(encFilePath)
    makedirs(encFilePath)

    outFilePath = pjoin(outPath, "app.asar")
    print(f"set outFilePath: {outFilePath}")
    fileArr = listdir(path)

    for name in fileArr:
        fpath = pjoin(path, name)
        if isdir(fpath):
            print("TODO: found folder")
            raise IsADirectoryError

        scode = open(fpath, "rb").read()
        print(f"open file: {name}")
        if isfile(fpath) and name.endswith(".js"):
            scode = encScript(scode)

        open(pjoin(encFilePath, name), "wb").write(scode)
        print(f"encrypt and save file: {name}")

    print("ready to pack")
    pack_asar(encFilePath, outFilePath)
    print("pack done")

    rmtree(encFilePath)
    print("remove temp dir")
