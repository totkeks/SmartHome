if status is-interactive
	if not test -f ~/.config/fish/completions/podman.fish
		podman completion -f ~/.config/fish/completions/podman.fish fish
		echo "Podman completions generated."
	end
end
