{.used.}

import clurp, os, strutils
const lib = "../../libwebp/"
const libwebpPath = currentSourcePath().replace("\\", "/").parentDir() / lib

{.passC: "-I" & libwebpPath.}

const sources = @[
    lib & "src/dec/alpha_dec.c",
    lib & "src/dec/frame_dec.c",
    lib & "src/dec/idec_dec.c",
    lib & "src/dec/io_dec.c",
    lib & "src/dec/quant_dec.c",
    lib & "src/dec/tree_dec.c",
    lib & "src/dec/vp8_dec.c",
    lib & "src/dec/vp8l_dec.c",
    lib & "src/dec/webp_dec.c",
    lib & "src/dec/buffer_dec.c",
    lib & "src/dsp/alpha_processing.c",
    lib & "src/dsp/alpha_processing_mips_dsp_r2.c",
    lib & "src/dsp/alpha_processing_neon.c",
    lib & "src/dsp/alpha_processing_sse2.c",
    lib & "src/dsp/alpha_processing_sse41.c",
    lib & "src/dsp/cpu.c",
    lib & "src/dsp/dec.c",
    lib & "src/dsp/dec_clip_tables.c",
    lib & "src/dsp/dec_mips32.c",
    lib & "src/dsp/dec_mips_dsp_r2.c",
    lib & "src/dsp/dec_msa.c",
    lib & "src/dsp/dec_neon.c",
    lib & "src/dsp/dec_sse2.c",
    lib & "src/dsp/dec_sse41.c",
    lib & "src/dsp/filters.c",
    lib & "src/dsp/filters_mips_dsp_r2.c",
    lib & "src/dsp/filters_msa.c",
    lib & "src/dsp/filters_neon.c",
    lib & "src/dsp/filters_sse2.c",
    lib & "src/dsp/lossless.c",
    lib & "src/dsp/lossless_mips_dsp_r2.c",
    lib & "src/dsp/lossless_msa.c",
    lib & "src/dsp/lossless_neon.c",
    lib & "src/dsp/lossless_sse2.c",
    lib & "src/dsp/rescaler.c",
    lib & "src/dsp/rescaler_mips32.c",
    lib & "src/dsp/rescaler_mips_dsp_r2.c",
    lib & "src/dsp/rescaler_msa.c",
    lib & "src/dsp/rescaler_neon.c",
    lib & "src/dsp/rescaler_sse2.c",
    lib & "src/dsp/upsampling.c",
    lib & "src/dsp/upsampling_mips_dsp_r2.c",
    lib & "src/dsp/upsampling_msa.c",
    lib & "src/dsp/upsampling_neon.c",
    lib & "src/dsp/upsampling_sse2.c",
    lib & "src/dsp/upsampling_sse41.c",
    lib & "src/dsp/yuv.c",
    lib & "src/dsp/yuv_mips32.c",
    lib & "src/dsp/yuv_mips_dsp_r2.c",
    lib & "src/dsp/yuv_neon.c",
    lib & "src/dsp/yuv_sse2.c",
    lib & "src/dsp/yuv_sse41.c",
    lib & "src/utils/bit_reader_utils.c",
    lib & "src/utils/color_cache_utils.c",
    lib & "src/utils/filters_utils.c",
    lib & "src/utils/huffman_utils.c",
    lib & "src/utils/quant_levels_dec_utils.c",
    lib & "src/utils/random_utils.c",
    lib & "src/utils/rescaler_utils.c",
    lib & "src/utils/thread_utils.c",
    lib & "src/utils/utils.c"
]

clurp(sources, includeDirs = [libwebpPath])