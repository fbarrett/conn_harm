GOAL: implement connectome harmonic analysis described in:

    Atasoy S, Donnelly I, Pearson J (2015). Human brain networks function
        in connectome-specific harmonic waves. Nature Communications, 7:10340

    Atasoy S, Roseman L, Kaelen M, Kringelbach ML, Deco G, Carhart-Harris RL
        (2017). Connectome-harmonic decomposition of human brain activity
        reveals dynamical repertoire re-organization under LSD. Scientific
        Reports, 7:17661

WORKFLOW:

    1. conn_harm_preproc.m
        - BET used to skull-strip MPRAGE
        - Freesurfer used to preprocess MPRAGE/generate cortical surfaces,
            average vertex space projected back to subject native space
        - SPM used to coregister EPI to MPRAGE, DTI to EPI
        - mrDiffusion used to preprocess coregistered diffusion data
    2. conn_harm_fiberTrack.m
        - mrDiffusion used for fiber tracking
    3. plot_conn_harm.m
        - using HCP visualization scripts from CanLab
