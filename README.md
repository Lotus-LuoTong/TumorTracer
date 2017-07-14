# TumorTracer
trace tumor origin using methylation level of ctDNA.

# Tumor Burden Adjust
adjust.pl can adjust beta values according to tumor burden theta it estimates. The input format of adjust.pl is as follows:
==========================================
probe	sampleID1	sampleID2	sampleID3
cg00000165	0.3	0.5	0.2
cg00000236	0.1	0.2	0.7
cg00000289	0.7 0.8	0.4
==========================================	
adjust.pl will give you an adjust beta value matrix, of which the format is exactly the same as your input.
