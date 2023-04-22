defmodule LoadBalancer do
    alias Gateway.Cache.ECache

    @doc """
        Checks if there is any available service registered in the cache
    """
    def any_available?(service) do
        ECache.command("LLEN #{service}") > 0
    end

    @doc """
        Returns next service address
    """
    def next(service) do
        ECache.command("RPOPLPUSH #{service} #{service}")
    end
end
