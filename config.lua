TMGWeed = {}

TMGWeed.Progress = { -- How much progress will be added to a healthy plant every GrowthTick
    min = 1,        -- Changing this will change growth time progression. Example 1 to 50 will give 50 progression in the 9.6 min cycle.
    max = 3,        -- See above, make sure max is more then min.
}

TMGWeed.ShowStages = true -- Show the stages of the plants
TMGWeed.GrowthTick = 9.6  -- Amount of time (in mins) to increase plant growth & update health / nutrition (every second tick)
TMGWeed.FoodUsage = 1     -- Amount of food to use per-tick

TMGWeed.StageLabels = {
    [1] = 'Germination',
    [2] = 'Seedling',
    [3] = 'Vegetative',
    [4] = 'Budding',
    [5] = 'Pre-flowering',
    [6] = 'Flowering',
    [7] = 'Ready for harvest',
}

TMGWeed.DefaultProps = {
    [1] = 'bkr_prop_weed_01_small_01c',
    [2] = 'bkr_prop_weed_01_small_01b',
    [3] = 'bkr_prop_weed_01_small_01a',
    [4] = 'bkr_prop_weed_med_01b',
    [5] = 'bkr_prop_weed_lrg_01a',
    [6] = 'bkr_prop_weed_lrg_01b',
    [7] = 'bkr_prop_weed_lrg_01b',
}

TMGWeed.Plants = {
    ogkush = {
        label = 'OGKush 2g',
        item = 'weed_ogkush',
        stages = TMGWeed.DefaultProps,
        highestStage = 7,
    },
    amnesia = {
        label = 'Amnesia 2g',
        item = 'weed_amnesia',
        stages = TMGWeed.DefaultProps,
        highestStage = 7,
    },
    skunk = {
        label = 'Skunk 2g',
        item = 'weed_skunk',
        stages = TMGWeed.DefaultProps,
        highestStage = 7,
    },
    ak47 = {
        label = 'AK47 2g',
        item = 'weed_ak47',
        stages = TMGWeed.DefaultProps,
        highestStage = 7,
    },
    purplehaze = {
        label = 'Purple Haze 2g',
        item = 'weed_purplehaze',
        stages = TMGWeed.DefaultProps,
        highestStage = 7,
    },
    whitewidow = {
        label = 'White Widow 2g',
        item = 'weed_whitewidow',
        stages = TMGWeed.DefaultProps,
        highestStage = 7,
    },
}
