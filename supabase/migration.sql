-- Run this once in Supabase Dashboard > SQL Editor.
-- The Flutter app stores one public product image in products.image_url.

alter table public.products
  add column if not exists image_url text;

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (product_id, buyer_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  text_content text,
  image_url text,
  created_at timestamptz not null default now()
);

alter table public.chats enable row level security;
alter table public.messages enable row level security;

create policy "Users can view their chats"
on public.chats for select
to authenticated
using (auth.uid() = buyer_id or auth.uid() = seller_id);

create policy "Buyers can create chats"
on public.chats for insert
to authenticated
with check (auth.uid() = buyer_id);

create policy "Chat participants can view messages"
on public.messages for select
to authenticated
using (
  exists (
    select 1 from public.chats
    where chats.id = messages.chat_id
      and (chats.buyer_id = auth.uid() or chats.seller_id = auth.uid())
  )
);

create policy "Chat participants can send messages"
on public.messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.chats
    where chats.id = messages.chat_id
      and (chats.buyer_id = auth.uid() or chats.seller_id = auth.uid())
  )
);

insert into storage.buckets (id, name, public)
values ('item_images', 'item_images', true), ('chat_images', 'chat_images', true)
on conflict (id) do update set public = excluded.public;

create policy "Authenticated users can upload item images"
on storage.objects for insert
to authenticated
with check (bucket_id in ('item_images', 'chat_images'));

create policy "Public images are readable"
on storage.objects for select
to public
using (bucket_id in ('item_images', 'chat_images'));
