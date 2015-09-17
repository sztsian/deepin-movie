#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2014 ~ 2015 Deepin, Inc.
#               2014 ~ 2015 Wang YaoHua
#
# Author:     Wang YaoHua <mr.asianwang@gmail.com>
# Maintainer: Wang YaoHua <mr.asianwang@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
from PIL import Image
from PyQt5.QtGui import QIcon

HOME_DIR = os.path.expanduser("~")
def icon_from_theme(theme_name, icon_name):
    QIcon.setThemeSearchPaths([os.path.join(HOME_DIR, ".icons"),
        os.path.join(HOME_DIR, ".local/share/icons"),
        "/usr/local/share/icons",
        "/usr/share/icons",
        ":/icons"])
    QIcon.setThemeName(theme_name)
    return QIcon.fromTheme(icon_name)

def rotatePicture(src, rotation, dest):
	img = Image.open(src)
	img.rotate(rotation).save(dest)

def flipPicture(src, flipHorizontal, flipVertical, dest):
	img = Image.open(src)

	if flipHorizontal: img = img.transpose(Image.FLIP_LEFT_RIGHT)
	if flipVertical: img = img.transpose(Image.FLIP_TOP_BOTTOM)

	img.save(dest)