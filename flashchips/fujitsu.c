/*
 * This file is part of the flashrom project.
 *
 * Copyright (C) 2000 Silicon Integrated System Corporation
 * Copyright (C) 2004 Tyan Corp
 * Copyright (C) 2005-2008 coresystems GmbH <stepan@openbios.org>
 * Copyright (C) 2006-2009 Carl-Daniel Hailfinger
 * Copyright (C) 2009 Sean Nelson <audiohacked@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

	{
		.vendor		= "Fujitsu",
		.name		= "MBM29F004BC",
		.bustype	= BUS_PARALLEL,
		.manufacture_id	= FUJITSU_ID,
		.model_id	= FUJITSU_MBM29F004BC,
		.total_size	= 512,
		.page_size	= 64 * 1024,
		.feature_bits	= FEATURE_ADDR_2AA | FEATURE_EITHER_RESET,
		.tested		= TEST_UNTESTED,
		.probe		= PROBE_JEDEC,
		.probe_timing	= TIMING_ZERO,	/* Datasheet has no timing info specified */
		.block_erasers	=
		{
			{
				.eraseblocks = {
					{16 * 1024, 1},
					{8 * 1024, 2},
					{32 * 1024, 1},
					{64 * 1024, 7},
				},
				.block_erase = JEDEC_SECTOR_ERASE,
			}, {
				.eraseblocks = { {512 * 1024, 1} },
				.block_erase = JEDEC_CHIP_BLOCK_ERASE,
			},
		},
		.write		= 0,
		.read		= READ_MEMMAPPED,
		.voltage	= {4500, 5500},
	},

	{
		.vendor		= "Fujitsu",
		.name		= "MBM29F004TC",
		.bustype	= BUS_PARALLEL,
		.manufacture_id	= FUJITSU_ID,
		.model_id	= FUJITSU_MBM29F004TC,
		.total_size	= 512,
		.page_size	= 64 * 1024,
		.feature_bits	= FEATURE_ADDR_2AA | FEATURE_EITHER_RESET,
		.tested		= TEST_UNTESTED,
		.probe		= PROBE_JEDEC,
		.probe_timing	= TIMING_ZERO,	/* Datasheet has no timing info specified */
		.block_erasers	=
		{
			{
				.eraseblocks = {
					{64 * 1024, 7},
					{32 * 1024, 1},
					{8 * 1024, 2},
					{16 * 1024, 1},
				},
				.block_erase = JEDEC_SECTOR_ERASE,
			}, {
				.eraseblocks = { {512 * 1024, 1} },
				.block_erase = JEDEC_CHIP_BLOCK_ERASE,
			},
		},
		.write		= 0,
		.read		= READ_MEMMAPPED,
		.voltage	= {4500, 5500},
	},

	{
		/* FIXME: this has WORD/BYTE sequences; 2AA for word, 555 for byte */
		.vendor		= "Fujitsu",
		.name		= "MBM29F400BC",
		.bustype	= BUS_PARALLEL,
		.manufacture_id	= FUJITSU_ID,
		.model_id	= FUJITSU_MBM29F400BC,
		.total_size	= 512,
		.page_size	= 64 * 1024,
		.feature_bits	= FEATURE_ADDR_SHIFTED | FEATURE_ADDR_2AA | FEATURE_EITHER_RESET,
		.tested		= TEST_UNTESTED,
		.probe		= PROBE_JEDEC,
		.probe_timing	= 10, // FIXME: check datasheet. Using the 10 us from probe_m29f400bt
		.block_erasers	=
		{
			{
				.eraseblocks = {
					{16 * 1024, 1},
					{8 * 1024, 2},
					{32 * 1024, 1},
					{64 * 1024, 7},
				},
				.block_erase = JEDEC_SECTOR_ERASE,
			}, {
				.eraseblocks = { {512 * 1024, 1} },
				.block_erase = JEDEC_CHIP_BLOCK_ERASE,
			},
		},
		.write		= WRITE_JEDEC1,
		.read		= READ_MEMMAPPED,
		.voltage	= {4750, 5250}, /* 4.75-5.25V for type -55, others 4.5-5.5V */
	},

	{
		.vendor		= "Fujitsu",
		.name		= "MBM29F400TC",
		.bustype	= BUS_PARALLEL,
		.manufacture_id	= FUJITSU_ID,
		.model_id	= FUJITSU_MBM29F400TC,
		.total_size	= 512,
		.page_size	= 64 * 1024,
		.feature_bits	= FEATURE_ADDR_SHIFTED | FEATURE_ADDR_AAA | FEATURE_EITHER_RESET,
		.tested		= TEST_UNTESTED,
		.probe		= PROBE_JEDEC,
		.probe_timing	= 10, // FIXME: check datasheet. Using the 10 us from probe_m29f400bt
		.block_erasers	=
		{
			{
				.eraseblocks = {
					{64 * 1024, 7},
					{32 * 1024, 1},
					{8 * 1024, 2},
					{16 * 1024, 1},
				},
				.block_erase = JEDEC_SECTOR_ERASE,
			}, {
				.eraseblocks = { {512 * 1024, 1} },
				.block_erase = JEDEC_CHIP_BLOCK_ERASE,
			},
		},
		.write		= WRITE_JEDEC1,
		.read		= READ_MEMMAPPED,
		.voltage	= {4750, 5250}, /* 4.75-5.25V for type -55, others 4.5-5.5V */
	},

	{
		.vendor		= "Fujitsu",
		.name		= "MBM29LV160BE",
		.bustype	= BUS_PARALLEL,
		.manufacture_id	= FUJITSU_ID,
		.model_id	= FUJITSU_MBM29LV160BE,
		.total_size	= 2 * 1024,
		.page_size	= 0,
		.feature_bits	= FEATURE_ADDR_SHIFTED | FEATURE_SHORT_RESET,
		.tested		= TEST_UNTESTED,
		.probe		= PROBE_JEDEC,
		.probe_timing	= 10, // FIXME: check datasheet. Using the 10 us from probe_m29f400bt
		.block_erasers	=
		{
			{
				.eraseblocks = {
					{16 * 1024, 1},
					{8 * 1024, 2},
					{32 * 1024, 1},
					{64 * 1024, 31},
				},
				.block_erase = JEDEC_BLOCK_ERASE,
			}, {
				.eraseblocks = { {2048 * 1024, 1} },
				.block_erase = JEDEC_CHIP_BLOCK_ERASE,
			},
		},
		.write		= WRITE_JEDEC1, /* Supports a fast mode too */
		.read		= READ_MEMMAPPED,
		.voltage	= {3000, 3600}, /* 3.0-3.6V for type -70, others 2.7-3.6V */
	},

	{
		.vendor		= "Fujitsu",
		.name		= "MBM29LV160TE",
		.bustype	= BUS_PARALLEL,
		.manufacture_id	= FUJITSU_ID,
		.model_id	= FUJITSU_MBM29LV160TE,
		.total_size	= 2 * 1024,
		.page_size	= 0,
		.feature_bits	= FEATURE_ADDR_SHIFTED | FEATURE_SHORT_RESET,
		.tested		= TEST_UNTESTED,
		.probe		= PROBE_JEDEC,
		.probe_timing	= 10, // FIXME: check datasheet. Using the 10 us from probe_m29f400bt
		.block_erasers	=
		{
			{
				.eraseblocks = {
					{64 * 1024, 31},
					{32 * 1024, 1},
					{8 * 1024, 2},
					{16 * 1024, 1},
				},
				.block_erase = JEDEC_BLOCK_ERASE,
			}, {
				.eraseblocks = { {2048 * 1024, 1} },
				.block_erase = JEDEC_CHIP_BLOCK_ERASE,
			},
		},
		.write		= WRITE_JEDEC1, /* Supports a fast mode too */
		.read		= READ_MEMMAPPED,
		.voltage	= {3000, 3600}, /* 3.0-3.6V for type -70, others 2.7-3.6V */
	},
