include { FAST5_to_POD5 ; BASECALL } from '../modules/basecall.nf'

workflow BASECALLING {
    take:
        pod5_path
        fast5_path
        basecall_speed
        basecall_mods
        basecall_config
        basecall_trim
        qscore_thresh
        barcoding_kit
        trimmed_barcodes
        gpu_devices
        reference_file
        
    main:
        FAST5_to_POD5(fast5_path)
        pod5_path = FAST5_to_POD5.out.mix(pod5_path)
        
        BASECALL(pod5_path, basecall_speed, basecall_mods, basecall_config, basecall_trim, qscore_thresh, barcoding_kit,  trimmed_barcodes, gpu_devices, reference_file)
        bams = BASECALL.out.bam.toSortedList { a, b -> a[0] <=> b[0] }.flatten().buffer(size: 2)
        txts = BASECALL.out.txt.toSortedList { a, b -> a.baseName <=> b.baseName }.flatten()
        
    emit:
    bam_files = bams
    txt_files = txts
}
