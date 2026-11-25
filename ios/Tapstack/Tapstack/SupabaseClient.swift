//
//  SupabaseClient.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import Supabase

// one connection the whole app uses
let supabase = SupabaseClient(supabaseURL: Secrets.supabaseURL, supabaseKey: Secrets.supabaseKey)
