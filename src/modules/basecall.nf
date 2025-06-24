process FAST5_to_POD5 {
    publishDir "results/${params.out_dir}/fast5_to_pod5/${id}/", mode: "copy", overwrite: true
    label 'cpu'

    input:
        tuple val(id), path(fast5)

    output:
        tuple val("${id}"), path("*.pod5")

    script:
        """
        pod5 convert fast5 *.fast5 \
        --output . \
        --one-to-one . \
        --threads 12
        """
}

process BASECALL {
    publishDir "results/${params.out_dir}/basecalling_output/", mode: "copy", overwrite: true
    label 'gpu'

    input:
        tuple val(id), path(pod5_dir)
        val basecall_speed
        val basecall_mods
        val basecall_config
        val basecall_trim
        val qscore_thresh
        val barcoding_kit
        val trimmed_barcodes
        val gpu_devices
        path reference_file

    output:
        path ("*.bam"), emit: bam
        path ("*.txt"), emit: txt

    script:
        """
        echo "Basecalling started for: ${id}"
        if [[ "${basecall_config}" == "None" ]]; then
            if [[ "${basecall_mods}" == "None" ]]; then
                dorado basecaller "${basecall_speed}" . \
                ${barcoding_kit != "None" ? "--kit-name ${barcoding_kit}" : ""} \
                --trim "${basecall_trim}" \
                --min-qscore "${qscore_thresh}" \
                --reference "${reference_file}" \
                --device "cuda:${gpu_devices}" > "${id}.bam" 
            else
                dorado basecaller "${basecall_speed},${basecall_mods}" . \
                ${barcoding_kit != "None" ? "--kit-name ${barcoding_kit}" : ""} \
                --trim "${basecall_trim}" \
                --min-qscore "${qscore_thresh}" \
                --reference "${reference_file}" \
                --device "cuda:${gpu_devices}" > "${id}.bam"
            fi
        else
                dorado basecaller "${basecall_config}" . \
                ${barcoding_kit != "None" ? "--kit-name ${barcoding_kit}" : ""} \
                --trim "${basecall_trim}" \
                --min-qscore "${qscore_thresh}" \
                --reference "${reference_file}" \
                --device "cuda:${gpu_devices}" > "${id}.bam"
        fi

        echo "Basecalling completed, sorting bams..."
        samtools sort -@ 12 "${id}.bam" -o "${id}_sorted.bam"
        rm "${id}.bam"
        mv "${id}_sorted.bam" "${id}.bam"

        echo "Bams sorted, demultiplexing..."
        if [[ "${trimmed_barcodes}" == "True" ]]; then
            echo "Demultiplexing with barcode trimming..."
            dorado demux --output-dir "./demux_data/" --no-classify "${id}.bam"
        else
            echo "Demultiplexing and barcode trimming..."
            dorado demux --trim "${basecall_trim}" --output-dir "./demux_data/" "${id}.bam"
        fi
        
        echo "Demultiplexing completed, sorting barcode files..."
        cd ./demux_data/
        for file in *; do
            samtools sort -@ 12 "\$file" -o "${id}_\$file"
            rm "\$file"
        done

        cd ../
        mv ./demux_data/* ./
        rm -r ./demux_data/
        
        echo "Bams sorted, generating summary with dorado..."
        for file in *.bam; do
            new_id="\${file%%.*}"
            dorado summary "\$file" > "\${new_id}.txt"
        done
        echo "Process completed for: ${id}"

        # echo "Bams sorted, generating summary with dorado..."
        # dorado summary "${id}.bam" > "${id}.txt"
        # echo "Process completed for: ${id}"
        """
}