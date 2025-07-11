# nanopore

NextFlow pipeline used by the Developmental Cognitive Neuroscience Lab (DCNL) to process Oxford Nanopore (ONT) DNA methylation data. This repository is currently mainted by the DCNL and the Artificial Intelligence and Data Science Center (CIACD) at PUC-RS.

## Table of Contents

1. [Getting Started](#getting-started)
1. [Pipeline paramters](#pipeline-parameters)
1. [Pipeline output directory](#pipeline-output-directory)
1. [Examples](#examples)
1. [Useful links](#useful-links)

## Getting Started

1. This pipeline assumes you're running a **GNU/Linux** distribution, such as Debian or Ubuntu.

1. Install `git`, `java`, `nextflow` and `apptainer`:

    - Install Git and LZ4 compression library:

      ```sh
      sudo apt install git lz4
      ```

    - Install Java: install either [OpenJRE/JDK][openjava] (**recommended, see below**) or [OracleJRE/JDK][oraclejava]. To install both openjre and openjdk using Debian/Ubuntu:

      ```sh
      sudo apt install default-jre default-jdk
      ```

    - Install [NextFlow][nextflow-docs-install] (skip Java installation)
    - Install [Apptainer][apptainer-docs-install-deb]
    - Install [NVIDIA Container Toolkit][nvidia-container-toolkit]: This enables Apptainer to access your GPU during basecalling. After installing it, to know if you have GPU support inside the container you can download a test container and check it by running:
  
    ```sh
    apptainer pull docker://nvidia/cuda:12.2.0-base-ubuntu22.04 && apptainer exec --nvccli cuda_12.2.0-base-ubuntu22.04.sif nvidia-smi
    ```

1. Check that all dependencies are accessible via your users `$PATH`:

    ```sh
    which {git,lz4,java,apptainer,nextflow}
    ```

    ```txt
    /usr/bin/git
    /usr/bin/lz4
    /usr/bin/java
    /usr/bin/apptainer
    /home/$USER/.local/bin/nextflow
    ```

1. Clone this repository and change directory to it:

    ```sh
    git clone https://gmapsrv.pucrs.br/gitlab/ccd-public/nanopore.git
    cd nanopore/
    ```

1. Make sure you have both the sequencing and reference genomes/assemblies files you need to run the pipeline. By convention, the sequencing files (`.fast5` or `.pod5` format) should be stored on `data/` (`mkdir data`), while the reference files (`.fa` format) should be stored on `references/`. Reference files are specific to the organism under study (human, rat, etc.).

1. Build your container image as follows:

    > **Note.** This will take a while to complete...

    ```sh
    mkdir images
    apptainer build \
      --mksquashfs-args="-comp lz4" \
      images/debian-nanopore.sif \
      containers/debian-nanopore.def
    ```
    If the container build fails due to size, it may be related to limitations in the **tmp/** folder, change it with ``export APPTAINER_TMPDIR="path/"``. See [documentation](https://apptainer.org/docs/user/1.0/build_env.html#temporary-folders) for details.

1. You should now be able to run the `nextflow` pipeline (`src/main.nf`). See [Pipeline parameters](#pipeline-parameters) and [Examples](#examples) for details.

[openjava]:https://openjdk.org/install/
[oraclejava]:https://www.java.com/en/download/linux_manual.jsp
[nextflow-docs-install]:https://www.nextflow.io/docs/latest/install.html#install-nextflow
[apptainer-docs-install-deb]:https://apptainer.org/docs/admin/main/installation.html#install-debian-packages
[nvidia-container-toolkit]:https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

[top](#table-of-contents)

## Pipeline parameters

The default values for all parameters are set in `src/nexflow.config`. Please notice that it's required to overwrite a few because they depend on the procedure you need to run (e.g., `--step`). The specifics of each are described next.

### Global options

```txt
--project_name

<Type: String. A short name used to identify a project. Default: "default">
```

```txt
--step

<Type: String. Options are "1", "2_from_step_1", "2_from_minknow", "3". Select 1 for basecalling. Select "2_from_step_1" for alignment filtering and quality control continuing after executing step 1 of this pipeline. Select "2_from_minknow" for alignment filtering and quality control from input basecalled using MinKNOW. Select "3" for methylation call pre-processing with modkit and generating a thorough multiQC report for sequencing stats. This parameter needs to be set for the pipeline to run. Default: "None">
```

```txt
--out_dir

<Type: Path. Name of output directory. Output files/directories will be output to "./results/<out_dir>/" in the directory you submitted the pipeline from. Default: "results_<project_name>/">
```

```txt
--steps_2_and_3_input_directory

<Type: Path. When performing a step other than 1, this parameter must be set to the output path of the step 1. Example: "./results/<out_dir>". Default = "None">
```

```txt
--prefix

<Type: String. Adds a prefix to the beggining of your filenames, good when wanting to keep track of batches of data. Example: "Batch_1". Default: "None">
```

### Step 1: Basecalling

Many of the parameters for this step are based on dorado basecaller, see their [documentation](https://github.com/nanoporetech/dorado) to understand it better.

```txt
--basecall_path

<Type: Path. Path to base directory containing all fast5 or pod5 files you want to basecall. It will automatically separate samples based on naming conventions and  directory structure. Default: "./data">
```

```txt
--basecall_speed

<Type: String. "fast", "hac", "sup". Default = "sup@latest">
```

```txt
--basecall_mods

<Type: String. Comma separated list of base modifications you want to basecall. See dorado docs for more information. Please note that you can't use more than one modification per nucleotide. Options: "4mC_5mC", "5mCG_5hmCG", "5mC_5hmC", "6mA". Default: "5mC_5hmC">
```

```txt
--basecall_compute

<Type: String. "gpu", "cpu". Default: "gpu". Allows users to choose to basecall with  CPU or GPU. CPU basecalling is super slow and should only be used for small test datasets when GPUs are not available. Also, use --basecall_speed "fast" when basecalling with CPU to make it less slow. Default: "gpu">
```

```txt
--basecall_config

<Type: String Configuration name for basecalling setting. This is not necessary since dorado  is able to automatically determine the appropriate configuration. Default: "None">
```

```txt
--basecall_trim

<Type: String. Options: "all", "primers", "adapters", "none". Default: "all">
```

```txt
--barcoding_kit

<Type: String. Kit name used to barcode the samples. Use "None" to skip --kit-name in basecalling. Default: "SQK-RBK114-24">
```

```txt
--qscore_thresh

<Type: Integer. Mean quality score threshold for basecalled reads to be considered passing. Default: 9>
```

```txt
--basecall_demux

<Type: Boolean. "True", "False". Whether you want the data to be demultiplexed setting it to "True" will perform demultiplexing. Default: false>
```

```txt
--trimmed_barcodes

<Type: Boolean. "True", "False". Only relevant is --demux is set to "True". if set to "True" barcodes will be trimmed during demultiplexing and will not be present in output "fastq" files. Default: "False">
```

```txt
--gpu_devices

<Type: String. Which gpu devices to use for basecalling. Only relevant when parameter "--basecall_compute" is set to "gpu". For troubleshooting, you can use the 'nvidia-smi' command to see all the available gpu devices. Options: "0", "0,1,2", ... . Default: "all".
```

### Step 2: Alignment Filtering and Quality Control

```txt
--qscore_thresh

<Type: Integer. Mean quality score threshold for basecalled reads to be considered passing. Should be set to the same value specified in step 1. Default: 9>
```

```txt
--mapq

<Type: Integer. Set it to the number you want to be used to filter ".bam" file by mapq. --mapq 10 filters out reads with MAPQ < 10. set it to 0 if don't want to filter out any reads. Default: 10>
```

```txt
--min_mapped_reads_thresh

<Type: Integer. Minimum number of primary mapped reads at or above MAPQ threshold for a barcode/sample to be considered valid for downstream analysis. Files below this threshold will not be processed any further. The default value is a good rule of thumb, but it can be decreased for small test datasets or increased for very large sequencing runs. Default: 500>
```

```txt
--is_barcoded

<Type: Boolean. Only applies if performing "step_2_from_minknow", this parameter will be ignore for "step_2_from_step_1". If is_barcoded is set to "True" the files will be grouped by barcode, otherwise all files will be grouped by sequencing run regardless of barcode. Default: True>
```

### Step 3: Methylation Calling and MultiQC

```txt
--multiqc_config

<Type: Path. MultiQC configuration file. We provide a template that works well under "./references/multiqc_config.yaml" in this repository, but you are welcome to customize it as you see fit. Default: "./references/multiqc_config.yaml">
```

### Config Profiles

The pipeline also supports running [pre-configured profiles](https://www.nextflow.io/docs/latest/config.html#config-profiles). The currently supported profiles are under the `src/configs/` dir and can be used via the parameter `-profile <name>` option in `nextflow run`. All such profiles make assumptions about the type of data to be used and where they are being stored/output.

[top](#table-of-contents)

## Pipeline output directory

1. `fast5_to_pod5`: One directory per sample. Only exists for sample that had any fast5 files converted into pod5 files for more efficient basecalling with Dorado.
1. `basecalling_output`: Dorado basecalling output. One ".bam"  file per sample (already mapped to the reference genome of choice and sorted). Also includes one sequencing summary file per sample. Reads for the same run will be separated into different fastq files based on barcode when demultiplexing is enabled.
1. `pycoqc_no_filter`: Includes pycoQC quality control reports for each sample with metrics prior to alignment filtering by MAPQ. PycoQC reports are output in both ".html" and ".json" format. The ".html" files can be imported into a personal computer and opened using any internet browser to provide a quick glance basic statistics from the sequencing run.
1. `pycoqc_filtered`: Includes pycoQC quality control reports for each sample with metrics post alignment filtering by MAPQ. PycoQC reports are output in both ".html" and ".json" format. The ".html" files can be imported into a personal computer and opened using any internet browser to provide a quick glance basic statistics from the sequencing run.
1. `multiqc_input/minimap2`: Includes ".flagstat" and ".idxstat" files generate with samtools from before and after alignment filtering. These files show number of reads per sample and number of reads per chromosome. This information is integrated in the final multiQC report.
1. `bam_filtering`: Output from filtering bam files. Filtered files only include primary alignments with MAPQ greater than or equal to what the user specified. This directory includes sorted ".bam" files from before and after filtering and their respective index ".bai" files.
1. `intermediate_qc_reports`: Intermediate quality control reports for each sample separated into 3 directories: "read_length", "number_of_reads", "quality_score_thresholds".
1. `modkit`: Directory with methylation calls, bed file pileup, and summary files generated using modkit. See [documentation](https://nanoporetech.github.io/modkit/quick_start.html) for more information.
1. `num_reads_report`: Three reports, one with number of reads for each sample, other with reads length, and another with MAPQ and PHRED quality scores used to filter the files.
1. `multiQC_output`: MultiQC output files, most importantly the ".html" report showing summary statistics for all file.
1. `calculate_coverage`: Two .tsv files containing the average coverage for each sample across every chromosome of the reference genome used. If a value is not present for a sample that means that chromosome had 0 coverage in that sample.
1. `minknow_converted_input`: Merged .bam files and sequencing_summary.txt files for each barcode.

[top](#table-of-contents)

## Examples

The following examples assume your current directory is the root directory of the project (`nanopore/`).

1. Set the following variables for your test run (see examples in the comments):

    ```sh
    # BASECALL_PATH="./data/test_data_minial/"
    export BASECALL_PATH=""
    # REFERENCE_FILE="./references/mouse_reference.fa"
    export REFERENCE_FILE=""
    # OUTPUT_DIR_NAME="test_gpu"
    export OUTPUT_DIR_NAME=""
    ```

1. STEP 1: GPU basecalling without demultiplexing

    ```sh
    nextflow ./src/main.nf \
            --basecall_path "$BASECALL_PATH" \
            --basecall_speed "hac" \
            --step 1 \
            --ref "$REFERENCE_FILE" \
            --gpu_devices "all" \
            --basecall_mods "5mC_5hmC" \
            --qscore_thresh 9 \
            --basecall_config "False" \
            --basecall_trim "none" \
            --basecall_compute "gpu" \
            --basecall_demux "False" \
            --queue_size 1 \
            --out_dir "$OUTPUT_DIR_NAME" \
            -resume
    ```

1. STEP 2A: Alignment Filtering and Quality Control from STEP 1

    ```sh
    nextflow ./src/main.nf \
              --steps_2_and_3_input_directory "./results/$OUTPUT_DIR_NAME/" \
              --min_mapped_reads_thresh 500 \
              --qscore_thresh 9 \
              --mapq 10 \
              --step "2_from_step_1" \
              -resume
    ```

1. STEP 2B (MinKNOW): Alignment Filtering and Quality Control from MinKNOW basecalling and alignment (bam files were generated by MinKNOW)

    ```sh
    nextflow ./src/main.nf \
              --steps_2_and_3_input_directory "./results/$OUTPUT_DIR_NAME/" \
              --min_mapped_reads_thresh 500 \
              --is_barcoded "True" \
              --qscore_thresh 9 \
              --mapq 10 \
              --step "2_from_step_1" \
              -resume
    ```

1. STEP 3: Methylation calling and MultiQC report

    ```sh
    nextflow ./src/main.nf \
              --steps_2_and_3_input_directory "./results/$OUTPUT_DIR_NAME/" \
              --multiqc_config "./references/multiqc_config.yaml" \
              --step 3 \
              -resume
    ```

Alternatively, you can  make use of an existing [configuration profile](#config-profiles) to run one or more of the mentioned steps without the need to specify all parameters (the profiles are optimized for specific types of analysis). For example, the `src/configs/human_blood.config` file implements the `human_blood_basecall` profile, which can be executed from the project root directory as follows:

```sh
nextflow ./src/main.nf -profile human_blood_basecall
```

[top](#table-of-contents)

## Useful links

- Main
  - [Nextflow](https://www.nextflow.io)
  - [Apptainer](https://apptainer.org)/[Singularity](https://docs.sylabs.io)
- Basecalling
  - [pod5](https://pypi.org/project/pod5/)
  - [dorado](https://github.com/nanoporetech/dorado)
- Quality Control
  - [PycoQC](https://github.com/a-slide/pycoQC)
  - [MultiQC](https://multiqc.info/)
- Alignment
  - [Minimap2](https://github.com/lh3/minimap2)
- Methylation Calling
  - [Modkit](https://github.com/nanoporetech/modkit)
- Other Genomics Tools
  - [Samtools](https://github.com/samtools/samtools)
- Other Software
  - [Conda](https://docs.conda.io/en/latest/)
  - [Bioconda](https://bioconda.github.io/)
  - [pip](https://pypi.org/project/pip/)

[top](#table-of-contents)
