# @Time   : 2023.09.19
# @Author : Darrius Lei
# @Email  : darrius.lei@outlook.com

import argparse, sys, logging, os
from lib import glb_var, json_util
from lib.callback import Logger, CustomException
#TODO： argparse
if __name__ == '__main__':
    if not os.path.exists('./cache/logger/'):
        os.makedirs('./cache/logger/')
    glb_var.__init__();
    log = Logger(
        level = logging.DEBUG,
        filename = './cache/logger/logger.log',
    ).get_log()
    glb_var.set_value('logger', log);
    parse = argparse.ArgumentParser();
    parse.add_argument('--config', '-cfg', type = str, default = None, help = 'config for run');
    parse.add_argument('--mode', type = str, default = 'train', help = 'train/test/train_and_test')

    args = parse.parse_args();

    if args.config is not None:
        pass;