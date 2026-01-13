# Reference

# TanStack Query Integration for TanStack Start

TanStack Query (formerly React Query) provides powerful data fetching and state management for TanStack Start applications, handling caching, synchronization, and background updates automatically.

## Overview

TanStack Query Features:

- **Smart Caching**: Automatic cache management with stale-while-revalidate pattern
- **Background Refetching**: Keep data fresh with automatic background updates
- **Optimistic Updates**: Update UI before server confirmation
- **Pagination & Infinite Queries**: Built-in support for complex data fetching patterns
- **Mutation Management**: Coordinated data mutations with automatic cache invalidation
- **DevTools**: Visual debugging and monitoring

## Installation & Setup

### Install Dependencies

```bash
npm install @tanstack/react-query @tanstack/react-query-devtools
npm install -D @tanstack/react-query-devtools
```

### Configure Root Provider

```typescript
// src/routes/__root.tsx
import {
  QueryClient,
  QueryClientProvider,
} from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      gcTime: 1000 * 60 * 10, // 10 minutes (formerly cacheTime)
      retry: 1,
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
    },
    mutations: {
      retry: 1,
    },
  },
});

export function RootLayout({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}
```

## Query Patterns

### Basic useQuery Hook

```typescript
// Fetch single resource
import { useQuery } from '@tanstack/react-query';

function UserProfile({ userId }) {
  const { data: user, isLoading, error } = useQuery({
    queryKey: ['user', userId],
    queryFn: async () => {
      const response = await fetch(`/api/users/${userId}`);
      if (!response.ok) throw new Error('Failed to fetch user');
      return response.json();
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

### Query with Options

```typescript
// Advanced configuration
const { data, isLoading, error, refetch, isFetching } = useQuery({
  queryKey: ['users', filters],
  queryFn: () => fetchUsers(filters),

  // Cache management
  staleTime: 5 * 60 * 1000,      // Data fresh for 5 min
  gcTime: 10 * 60 * 1000,        // Keep in cache for 10 min
  refetchInterval: 30 * 1000,    // Refetch every 30s

  // Refetch triggers
  refetchOnMount: true,
  refetchOnWindowFocus: true,
  refetchOnReconnect: true,

  // Error handling
  retry: 2,
  retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),

  // Enable/disable
  enabled: !!userId,  // Dependent queries

  // Placeholders
  placeholderData: keepPreviousData,  // Keep old data while loading new
});

return (
  <div>
    {isFetching && <span className="spinner">Refreshing...</span>}
    <UsersList users={data} />
    <button onClick={() => refetch()}>Refresh</button>
  </div>
);
```

### Dependent Queries

```typescript
// Chain queries based on conditions
function UserWithPosts({ userId }) {
  // First query
  const { data: user, isLoading: userLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });

  // Second query depends on first
  const { data: posts, isLoading: postsLoading } = useQuery({
    queryKey: ['posts', user?.id],
    queryFn: () => fetchPosts(user.id),
    enabled: !!user,  // Only run when user is loaded
  });

  if (userLoading) return <div>Loading user...</div>;
  if (postsLoading) return <div>Loading posts...</div>;

  return (
    <div>
      <h1>{user.name}</h1>
      {posts.map((post) => (
        <article key={post.id}>{post.title}</article>
      ))}
    </div>
  );
}
```

### Parallel Queries

```typescript
// Fetch multiple independent queries
function Dashboard() {
  const resultsUsers = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
  });

  const resultsAnalytics = useQuery({
    queryKey: ['analytics'],
    queryFn: fetchAnalytics,
  });

  const resultsPosts = useQuery({
    queryKey: ['posts'],
    queryFn: fetchPosts,
  });

  // Or use useQueries for dynamic lists
  const results = useQueries({
    queries: userIds.map((userId) => ({
      queryKey: ['user', userId],
      queryFn: () => fetchUser(userId),
    })),
  });

  const isLoading = results.some((r) => r.isLoading);

  return (
    <div>
      {isLoading ? <div>Loading...</div> : <Dashboard data={results} />}
    </div>
  );
}
```

## Pagination Patterns

### Simple Pagination

```typescript
function PostsList() {
  const [pageIndex, setPageIndex] = useState(0);

  const { data, isLoading, error } = useQuery({
    queryKey: ['posts', pageIndex],
    queryFn: () => fetchPosts(pageIndex),
  });

  return (
    <div>
      {data?.posts.map((post) => (
        <Post key={post.id} post={post} />
      ))}

      <div className="pagination">
        <button
          onClick={() => setPageIndex((p) => Math.max(p - 1, 0))}
          disabled={pageIndex === 0}
        >
          Previous
        </button>

        <span>Page {pageIndex + 1}</span>

        <button
          onClick={() => setPageIndex((p) => p + 1)}
          disabled={!data?.hasMore}
        >
          Next
        </button>
      </div>
    </div>
  );
}
```

### Infinite Queries

```typescript
// Infinite scroll / "Load more" pattern
function InfinitePostsList() {
  const {
    data,
    error,
    fetchNextPage,
    hasNextPage,
    isFetching,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['posts'],
    queryFn: ({ pageParam = 0 }) => fetchPosts(pageParam),
    getNextPageParam: (lastPage, pages) => lastPage.nextCursor,
  });

  return (
    <div>
      {data?.pages.map((page) =>
        page.posts.map((post) => (
          <Post key={post.id} post={post} />
        ))
      )}

      {hasNextPage && (
        <button onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
          {isFetchingNextPage ? 'Loading more...' : 'Load More'}
        </button>
      )}

      {isFetching && !isFetchingNextPage && <div>Refreshing...</div>}
    </div>
  );
}
```

## Mutation Patterns

### Basic Mutation

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

function CreatePostForm() {
  const queryClient = useQueryClient();

  const { mutate, isPending, error } = useMutation({
    mutationFn: async (newPost) => {
      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newPost),
      });
      if (!response.ok) throw new Error('Failed to create post');
      return response.json();
    },

    // Success handling
    onSuccess: (data) => {
      // Invalidate related queries
      queryClient.invalidateQueries({ queryKey: ['posts'] });

      // Or update manually
      queryClient.setQueryData(['post', data.id], data);
    },

    // Error handling
    onError: (error) => {
      console.error('Error creating post:', error);
    },

    // Final cleanup
    onSettled: () => {
      console.log('Mutation finished');
    },
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    mutate({
      title: formData.get('title'),
      content: formData.get('content'),
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="title" placeholder="Title" required />
      <textarea name="content" placeholder="Content" required />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
      {error && <div className="error">{error.message}</div>}
    </form>
  );
}
```

### Optimistic Updates

```typescript
// Update UI before server confirmation
function LikeButton({ postId, initialLikes }) {
  const queryClient = useQueryClient();

  const { mutate } = useMutation({
    mutationFn: async () => {
      const response = await fetch(`/api/posts/${postId}/like`, {
        method: 'POST',
      });
      if (!response.ok) throw new Error('Failed to like');
      return response.json();
    },

    onMutate: async () => {
      // Cancel in-flight queries
      await queryClient.cancelQueries({ queryKey: ['post', postId] });

      // Get previous data
      const previousData = queryClient.getQueryData(['post', postId]);

      // Update cache optimistically
      queryClient.setQueryData(['post', postId], (old) => ({
        ...old,
        likes: old.likes + 1,
      }));

      // Return context for rollback
      return { previousData };
    },

    // Rollback on error
    onError: (error, variables, context) => {
      queryClient.setQueryData(['post', postId], context.previousData);
    },

    // Refetch on success
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['post', postId] });
    },
  });

  return (
    <button onClick={() => mutate()}>
      Like {initialLikes + 1}
    </button>
  );
}
```

## Query Client Management

### Query Client Configuration

```typescript
import { QueryClient } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Stale time: how long until data is considered stale
      staleTime: Infinity,  // Never stale (good for static data)
      staleTime: 0,         // Always stale (always refetch)
      staleTime: 5 * 60 * 1000,  // 5 minutes (default)

      // GC time: how long to keep data after last use
      gcTime: 5 * 60 * 1000,

      // Retry on failure
      retry: 3,
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),

      // Refetch triggers
      refetchOnMount: true,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true,
    },

    mutations: {
      retry: 1,
    },
  },
});

// Clear all data on logout
function handleLogout() {
  queryClient.clear();
  redirectToLogin();
}

// Prefetch data for faster navigation
queryClient.prefetchQuery({
  queryKey: ['user'],
  queryFn: fetchUser,
  staleTime: 5 * 60 * 1000,
});
```

### Query Invalidation

```typescript
// Invalidate single query
queryClient.invalidateQueries({ queryKey: ['posts', 1] });

// Invalidate all queries by prefix
queryClient.invalidateQueries({ queryKey: ['posts'] });

// Invalidate with predicate
queryClient.invalidateQueries({
  predicate: (query) => query.queryKey[0] === 'posts',
});

// Refetch immediately
queryClient.refetchQueries({ queryKey: ['posts'] });

// Reset to initial state
queryClient.resetQueries({ queryKey: ['posts'] });
```

## Error Handling

### Global Error Handling

```typescript
// In QueryClientProvider setup
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        // Don't retry on 4xx errors
        if (error.status >= 400 && error.status < 500) {
          return false;
        }
        return failureCount < 3;
      },
    },
  },
});
```

### Component-level Error Handling

```typescript
function UsersList() {
  const { data, error, isError } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
  });

  if (isError) {
    if (error.status === 401) {
      return <RedirectToLogin />;
    }

    if (error.status === 403) {
      return <AccessDenied />;
    }

    return <ErrorBoundary error={error} />;
  }

  return <List items={data} />;
}
```

## Advanced Patterns

### Request Deduplication

```typescript
// Multiple components fetching same data
// Only makes one request (automatically deduped)

<Dashboard>
  <UserProfile userId={1} />  {/* Request 1 */}
  <UserSettings userId={1} /> {/* Uses cache from Request 1 */}
  <UserActivity userId={1} /> {/* Uses cache from Request 1 */}
</Dashboard>
```

### Background Refetch

```typescript
// Keep data fresh in background
const { isFetching } = useQuery({
  queryKey: ['notifications'],
  queryFn: fetchNotifications,
  refetchInterval: 30000,  // Refetch every 30 seconds
  refetchIntervalInBackground: true,  // Even when window not focused
});

return (
  <div>
    <NotificationsList />
    {isFetching && <div className="syncing">Syncing...</div>}
  </div>
);
```

### Offline Support

```typescript
// Handle offline gracefully
function useOnlineQuery(options) {
  const isOnline = useOnlineStatus();

  return useQuery({
    ...options,
    enabled: isOnline && (options.enabled !== false),
  });
}

// Usage
function MyComponent() {
  const { data } = useOnlineQuery({
    queryKey: ['data'],
    queryFn: fetchData,
  });

  return <div>{data?.content}</div>;
}
```

## Testing Queries

### Test Setup

```typescript
import { QueryClient } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';

function TestWrapper({ children }) {
  const testQueryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return (
    <QueryClientProvider client={testQueryClient}>
      {children}
    </QueryClientProvider>
  );
}

render(<YourComponent />, { wrapper: TestWrapper });
```

### Mocking Queries

```typescript
import { server } from './mocks/server';

test('displays user data', async () => {
  server.use(
    http.get('/api/users/1', () => {
      return HttpResponse.json({ id: 1, name: 'John' });
    })
  );

  render(<UserProfile userId={1} />, { wrapper: TestWrapper });

  await waitFor(() => {
    expect(screen.getByText('John')).toBeInTheDocument();
  });
});
```

## Performance Optimization

### Query Splitting

```typescript
// Instead of fetching everything
const { data: allData } = useQuery({
  queryKey: ['everything'],
  queryFn: fetchEverything,
});

// Split into focused queries
const { data: user } = useQuery({
  queryKey: ['user'],
  queryFn: fetchUser,
  staleTime: Infinity,
});

const { data: posts } = useQuery({
  queryKey: ['posts'],
  queryFn: fetchPosts,
  staleTime: 5 * 60 * 1000,
});
```

### Selective Refetch

```typescript
// Only invalidate affected queries
function handleUserUpdate(userId) {
  // Instead of invalidating all
  // queryClient.invalidateQueries({ queryKey: ['user'] });

  // Invalidate specific user
  queryClient.invalidateQueries({
    queryKey: ['user', userId],
  });
}
```

## DevTools Debugging

```typescript
// Import DevTools
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

// Add to provider
export function RootLayout({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools
        initialIsOpen={false}
        buttonPosition="bottom-right"
      />
    </QueryClientProvider>
  );
}
```

DevTools shows:
- All active queries and mutations
- Cache state
- Query history
- Performance timing
- Refetch triggers

## Common Patterns

### Prefetch for Navigation

```typescript
// src/routes/dashboard/index.tsx
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export function Dashboard() {
  const queryClient = useQueryClient();

  useEffect(() => {
    // Prefetch data for likely next page
    queryClient.prefetchQuery({
      queryKey: ['user-settings'],
      queryFn: fetchUserSettings,
    });
  }, [queryClient]);

  return <DashboardContent />;
}
```

### Sync with Server

```typescript
// Keep local state in sync with server
function useSyncedState(queryKey, initialValue) {
  const queryClient = useQueryClient();
  const { data } = useQuery({
    queryKey,
    queryFn: () => initialValue,
  });

  const { mutate } = useMutation({
    mutationFn: async (value) => {
      // Update server
      await saveToServer(value);
    },
    onSuccess: (data) => {
      // Update cache
      queryClient.setQueryData(queryKey, data);
    },
  });

  return [data, mutate];
}
```

## Resources

- [TanStack Query Documentation](https://tanstack.com/query/latest)
- [Query Patterns Guide](https://tanstack.com/query/latest/docs/react/guides/important-defaults)
- [Advanced Patterns](https://tanstack.com/query/latest/docs/react/guides/important-defaults)
