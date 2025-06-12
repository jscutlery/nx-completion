# Performance Testing Guide

This guide helps you verify that the nx-completion caching is working in real-world usage.

## Quick Performance Test

### 1. Setup
```bash
cd test
source ../nx-completion.plugin.zsh
```

### 2. First Completion (Cache Population)
```bash
# Type this and press TAB - this will populate the cache
nx <TAB>
```

**Expected**: Slight delay as cache is populated with projects, commands, etc.

### 3. Second Completion (Cache Usage)
```bash
# Type this and press TAB again - should be noticeably faster
nx <TAB>
```

**Expected**: Much faster response using cached data.

### 4. Test Different Completion Types

```bash
# Test project completion
nx build <TAB>      # First time: populates cache
nx build <TAB>      # Second time: uses cache

# Test target completion  
nx run <TAB>        # First time: populates cache
nx run <TAB>        # Second time: uses cache

# Test generator completion
nx generate <TAB>   # First time: populates cache  
nx generate <TAB>   # Second time: uses cache
```

## Performance Indicators

### ✅ **Good Performance Signs**
- Second completion is noticeably faster than first
- Large workspaces (many projects) show significant improvement
- Complex commands with many options complete quickly on repeat

### ⚠️ **Expected Behavior**
- First completion in a session may be slower (building cache)
- Cache refreshes every hour (may see one slow completion per hour)
- Very small workspaces may not show dramatic differences

## Cache Verification

You can verify caches are working by checking for cache files:

```bash
# Check zsh completion cache directory
ls ~/.zcompcache/ 2>/dev/null || ls ~/.zsh/cache/ 2>/dev/null

# Look for nx-related cache entries
# Cache may be stored in various locations depending on zsh config
```

## Troubleshooting

### Cache Not Working?
1. **Clear and rebuild cache**:
   ```bash
   rm -rf ~/.zcompdump* && autoload -U compinit && compinit -D
   ```

2. **Reload plugin**:
   ```bash
   source ../nx-completion.plugin.zsh
   ```

3. **Check workspace**:
   - Ensure you're in a valid Nx workspace
   - Verify `nx.json` exists
   - Check that project graph is accessible

### Still Having Issues?
- Run `./test-cache.zsh` to verify caching code is present
- Check that `jq` is installed and working
- Ensure proper zsh completion setup

## Expected Performance Improvements

| Workspace Size | First Completion | Subsequent Completions | Improvement |
|---------------|------------------|----------------------|-------------|
| Small (5-10 projects) | ~100-200ms | ~10-50ms | 2-4x faster |
| Medium (50-100 projects) | ~300-500ms | ~20-80ms | 4-6x faster |
| Large (200+ projects) | ~500-1000ms | ~50-150ms | 5-10x faster |

*Times are approximate and depend on system performance and workspace complexity.*

## Cache Lifecycle

1. **Initial Load**: First completion triggers cache population
2. **Fast Access**: Subsequent completions use cached data
3. **Auto Refresh**: Cache expires after 1 hour
4. **Re-population**: Next completion after expiry rebuilds cache

This ensures you always have up-to-date completion data while maintaining optimal performance.
