<script>
	import Button from './components/Button.svelte';
	import logo from './assets/logo.svg';

	let containerWidth = 0;
	let containerHeight = 0;

	const dotSize = 15;
	const gap = 10;
	const cellSize = dotSize + gap;
	const dotOffset = gap / 2;

	$: cols = Math.floor(containerWidth / cellSize) || 0;
	$: rows = Math.floor(containerHeight / cellSize) || 0;
</script>

<div
	class="flex min-h-screen flex-col bg-black font-['Pixelify_Sans'] text-white md:grid md:grid-cols-2"
>
	<div class="my-20 ml-2 flex flex-1 flex-col items-start justify-between gap-4 p-8 md:ml-10">
		<div class="flex flex-col items-start gap-10">
			<img src={logo} alt="CURB Logo" />
			<p class="text-4xl text-[#646464]">
				Vibe Coding sucks,<br />We made AI not suck.
			</p>
		</div>
		<div class="flex flex-col items-start gap-4">
			<Button
				label="Setup Guide For NeoVim"
				link="https://github.com/rinogodson/curb.nvim/blob/main/README.md#installation"
			/>
			<Button label="GitHub" link="https://github.com/rinogodson/curb.nvim" />
		</div>
	</div>

	<div class="flex w-full items-center justify-center">
		<div
			class="hidden h-[90%] w-[90%] place-items-center overflow-hidden md:grid"
			bind:clientWidth={containerWidth}
			bind:clientHeight={containerHeight}
		>
			{#if containerWidth && containerHeight}
				<svg width={cols * cellSize} height={rows * cellSize} class="block">
					{#each Array(rows) as _, r}
						{#each Array(cols) as _, c}
							<g class="group">
								<rect
									x={c * cellSize}
									y={r * cellSize}
									width={cellSize}
									height={cellSize}
									fill="transparent"
								/>

								<rect
									x={c * cellSize + dotOffset}
									y={r * cellSize + dotOffset}
									width={dotSize}
									height={dotSize}
									class="fill-[#D9D9D9]/10 group-hover:fill-[#FFBD89]"
								/>
							</g>
						{/each}
					{/each}
				</svg>
			{/if}
		</div>
	</div>
</div>
