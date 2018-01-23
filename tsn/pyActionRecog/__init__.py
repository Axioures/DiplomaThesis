from benchmark_db import *


split_parsers = dict()
split_parsers['ucf101'] = parse_ucf_splits
split_parsers['hmdb51'] = parse_hmdb51_splits
split_parsers['mov_cvsp'] = parse_cvsp_splits
split_parsers['hollywood2'] = parse_hollywood2_splits

def parse_split_file(dataset):
    sp = split_parsers[dataset]
    return sp()

