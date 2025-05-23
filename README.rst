flashrom README
===============

flashrom is a utility for detecting, reading, writing, verifying and erasing
flash chips. It is often used to flash BIOS/EFI/coreboot/firmware images
in-system using a supported mainboard, but it also supports flashing of network
cards (NICs), SATA controller cards, and other external devices which can
program flash chips.

It supports a wide range of flash chips (most commonly found in SOIC8, DIP8,
SOIC16, WSON8, PLCC32, DIP32, TSOP32, and TSOP40 packages), which use various
protocols such as LPC, FWH, parallel flash, or SPI.

Do not use flashrom on laptops (yet)! The embedded controller (EC) present in
many laptops might interact badly with any attempts to communicate with the
flash chip and may brick your laptop.

Please make a backup of your flash chip before writing to it.

Please see the flashrom(8) manpage :doc:`classic_cli_manpage`.

The list of platforms that package flashrom can be found on `repology.org <https://repology.org/project/flashrom/versions>`_.

Information about recent releases can be found in :doc:`/release_notes/index`.

Building / installing / packaging
---------------------------------

flashrom supports building with **make** and **meson**.

TLDR, building with meson
"""""""""""""""""""""""""

::

    meson setup builddir
    meson compile -C builddir
    meson test -C builddir
    meson install -C builddir

For full detailed instructions, follow the information in
:doc:`dev_guide/building_from_source`.

If you are interested in development, have a look at :doc:`dev_guide/development_guide`.

TLDR, building with make
""""""""""""""""""""""""

::

	make
	make install

For full detailed instructions, follow the information in
:doc:`dev_guide/building_with_make`

Contact
-------

The official flashrom website is:

  https://www.flashrom.org/

For available contact methods see :doc:`contact`
