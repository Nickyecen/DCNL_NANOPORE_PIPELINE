// Import Modules

include { PYCOQC_NO_FILTER ; PYCOQC_FILTER } from '../modules/pycoqc.nf'
include { FILTER_BAM } from '../modules/filter_bam.nf'
include { MAKE_QC_REPORT } from '../modules/num_reads_report.nf'

workflow FILTERING_AND_QC_FROM_STEP_1 {
    take:
        bam_files
        txt_files
        mapq
        qscore_thresh

    main:
        FILTER_BAM(bam_files, txt_files, mapq)
        PYCOQC_NO_FILTER(
            FILTER_BAM.out.id,
            FILTER_BAM.out.total_bam,
            FILTER_BAM.out.total_bai,
            FILTER_BAM.out.filtered_bam,
            FILTER_BAM.out.filtered_bai,
            FILTER_BAM.out.unfiltered_flagstat,
            FILTER_BAM.out.filtered_flagstat,
            FILTER_BAM.out.txt,
            qscore_thresh,
        )
        PYCOQC_FILTER(
            PYCOQC_NO_FILTER.out.id,
            PYCOQC_NO_FILTER.out.filtered_bam,
            PYCOQC_NO_FILTER.out.filtered_bai,
            PYCOQC_NO_FILTER.out.unfiltered_flagstat,
            PYCOQC_NO_FILTER.out.filtered_flagstat,
            PYCOQC_NO_FILTER.out.txt,
            qscore_thresh,
            PYCOQC_NO_FILTER.out.unfiltered_pyco_json,
        )
        MAKE_QC_REPORT(
            PYCOQC_FILTER.out.id,
            PYCOQC_FILTER.out.unfiltered_flagstat,
            PYCOQC_FILTER.out.filtered_flagstat,
            PYCOQC_FILTER.out.unfiltered_pyco_json,
            PYCOQC_FILTER.out.filtered_pyco_json,
            mapq,
            qscore_thresh,
        )
}
