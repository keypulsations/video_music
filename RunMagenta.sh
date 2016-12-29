#!/usr/local/bin/bash

MAGENTA_PATH=${1}
BUNDLE_PATH=${2}
PRIMER_MIDI=${3}
OUTPUT_PATH=${4}

cd ${MAGENTA_PATH}

bazel run //magenta/models/melody_rnn:melody_rnn_generate -- \
--config='attention_rnn' \
--bundle_file=${BUNDLE_PATH} \
--output_dir=${OUTPUT_PATH} \
--num_outputs=2 \
--num_steps=256 \
--primer_midi=${PRIMER_MIDI} \
--exclude_primer_midi=True
