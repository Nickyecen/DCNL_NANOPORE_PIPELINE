include { FAST5_to_POD5 ; BASECALL ; BASECALL_DEMUX } from '../modules/basecall.nf'

workflow BASECALLING {
    take:
        pod5_path
        fast5_path
        speed
        modifications
        config
        trim
        quality_score
        trim_barcode
        devices
        ref
    
    main:
        FAST5_to_POD5(fast5_path)
        pod5_path = FAST5_to_POD5.out.mix(pod5_path)
       
        if (params.basecall_demux == true) {
            BASECALL_DEMUX(pod5_path, speed, modifications, config, trim, quality_score, trim_barcode, devices, ref)
            bams = BASECALL_DEMUX.out.bam.toSortedList { a, b -> a.baseName <=> b.baseName }.flatten()
            txts = BASECALL_DEMUX.out.txt.toSortedList { a, b -> a.baseName <=> b.baseName }.flatten()
        }
        else {
            BASECALL(pod5_path, speed, modifications, config, trim, quality_score, devices, ref)
            bams = BASECALL.out.bam.toSortedList { a, b -> a[0] <=> b[0] }.flatten().buffer(size: 2)
            txts = BASECALL.out.txt.toSortedList { a, b -> a.baseName <=> b.baseName }.flatten()
        }

}
