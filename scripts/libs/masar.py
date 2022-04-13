# -*- coding:utf-8 -*-
"""
@Author: Mas0n
@File: masar.py
@Time: 2021-11-29 22:34
@Desc: It's all about getting better.
"""
import os
import io
import struct
import fileinput
import json


def round_up(i, m):
    return (i + m - 1) & ~(m - 1)


class Asar:
    def __init__(self, path, fp, header, base_offset):
        self.path = path
        self.fp = fp
        self.header = header
        self.base_offset = base_offset

    @classmethod
    def compress(cls, path):
        offset = 0
        paths = []

        def _path_to_dict(path):
            nonlocal offset, paths
            result = {'files': {}}
            for f in os.scandir(path):
                if os.path.isdir(f.path):
                    result['files'][f.name] = _path_to_dict(f.path)
                elif f.is_symlink():
                    result['files'][f.name] = {
                        'link': os.path.realpath(f.name)
                    }
                # modify
                elif f.name == "main.node":
                    size = f.stat().st_size
                    result['files'][f.name] = {
                        'size': size,
                        "unpacked": True
                    }
                else:
                    paths.append(f.path)
                    size = f.stat().st_size
                    result['files'][f.name] = {
                        'size': size,
                        'offset': str(offset)
                    }
                    offset += size
            return result

        def _paths_to_bytes(paths):
            _bytes = io.BytesIO()
            with fileinput.FileInput(files=paths, mode="rb") as f:
                for i in f:
                    _bytes.write(i)
            return _bytes.getvalue()

        header = _path_to_dict(path)
        header_json = json.dumps(header, sort_keys=True, separators=(',', ':')).encode('utf-8')
        header_string_size = len(header_json)
        data_size = 4
        aligned_size = round_up(header_string_size, data_size)
        header_size = aligned_size + 8
        header_object_size = aligned_size + data_size
        diff = aligned_size - header_string_size
        header_json = header_json + b'\0' * diff if diff else header_json
        fp = io.BytesIO()
        fp.write(struct.pack('<4I', data_size, header_size, header_object_size, header_string_size))
        fp.write(header_json)
        fp.write(_paths_to_bytes(paths))

        return cls(
            path=path,
            fp=fp,
            header=header,
            base_offset=round_up(16 + header_string_size, 4))

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.fp.close()


def pack_asar(source, dest):
    with Asar.compress(source) as a:
        with open(dest, 'wb') as fp:
            a.fp.seek(0)
            fp.write(a.fp.read())
