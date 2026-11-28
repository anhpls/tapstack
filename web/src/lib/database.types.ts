export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      memberships: {
        Row: {
          card_back_image_path: string | null
          card_image_aspect: number | null
          card_image_path: string | null
          created_at: string | null
          hidden_at: string | null
          id: string
          member_number: string
          shop_id: string
          user_id: string
        }
        Insert: {
          card_back_image_path?: string | null
          card_image_aspect?: number | null
          card_image_path?: string | null
          created_at?: string | null
          hidden_at?: string | null
          id?: string
          member_number?: string
          shop_id: string
          user_id: string
        }
        Update: {
          card_back_image_path?: string | null
          card_image_aspect?: number | null
          card_image_path?: string | null
          created_at?: string | null
          hidden_at?: string | null
          id?: string
          member_number?: string
          shop_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "memberships_shop_id_fkey"
            columns: ["shop_id"]
            isOneToOne: false
            referencedRelation: "shops"
            referencedColumns: ["id"]
          },
        ]
      }
      personal_cards: {
        Row: {
          category: string
          created_at: string | null
          id: string
          image_aspect: number | null
          image_back_aspect: number | null
          image_back_path: string | null
          image_path: string | null
          pending_stamps: number
          shop_name: string
          stamps_needed: number
          transferred_at: string | null
          user_id: string
        }
        Insert: {
          category: string
          created_at?: string | null
          id?: string
          image_aspect?: number | null
          image_back_aspect?: number | null
          image_back_path?: string | null
          image_path?: string | null
          pending_stamps?: number
          shop_name: string
          stamps_needed: number
          transferred_at?: string | null
          user_id?: string
        }
        Update: {
          category?: string
          created_at?: string | null
          id?: string
          image_aspect?: number | null
          image_back_aspect?: number | null
          image_back_path?: string | null
          image_path?: string | null
          pending_stamps?: number
          shop_name?: string
          stamps_needed?: number
          transferred_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
      redemption_requests: {
        Row: {
          code: string
          created_at: string | null
          expires_at: string
          id: string
          membership_id: string
          status: string
        }
        Insert: {
          code: string
          created_at?: string | null
          expires_at?: string
          id?: string
          membership_id: string
          status?: string
        }
        Update: {
          code?: string
          created_at?: string | null
          expires_at?: string
          id?: string
          membership_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "redemption_requests_membership_id_fkey"
            columns: ["membership_id"]
            isOneToOne: false
            referencedRelation: "memberships"
            referencedColumns: ["id"]
          },
        ]
      }
      redemptions: {
        Row: {
          created_at: string | null
          id: string
          membership_id: string
          redeemed_by: string | null
          reward: string
          stamps_used: number
        }
        Insert: {
          created_at?: string | null
          id?: string
          membership_id: string
          redeemed_by?: string | null
          reward: string
          stamps_used: number
        }
        Update: {
          created_at?: string | null
          id?: string
          membership_id?: string
          redeemed_by?: string | null
          reward?: string
          stamps_used?: number
        }
        Relationships: [
          {
            foreignKeyName: "redemptions_membership_id_fkey"
            columns: ["membership_id"]
            isOneToOne: false
            referencedRelation: "memberships"
            referencedColumns: ["id"]
          },
        ]
      }
      shop_members: {
        Row: {
          role: Database["public"]["Enums"]["shop_role"]
          shop_id: string
          user_id: string
        }
        Insert: {
          role: Database["public"]["Enums"]["shop_role"]
          shop_id: string
          user_id: string
        }
        Update: {
          role?: Database["public"]["Enums"]["shop_role"]
          shop_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "shop_members_shop_id_fkey"
            columns: ["shop_id"]
            isOneToOne: false
            referencedRelation: "shops"
            referencedColumns: ["id"]
          },
        ]
      }
      shops: {
        Row: {
          category: string
          color_hex: string
          created_at: string | null
          id: string
          is_test: boolean
          name: string
        }
        Insert: {
          category: string
          color_hex?: string
          created_at?: string | null
          id?: string
          is_test?: boolean
          name: string
        }
        Update: {
          category?: string
          color_hex?: string
          created_at?: string | null
          id?: string
          is_test?: boolean
          name?: string
        }
        Relationships: []
      }
      stamp_programs: {
        Row: {
          id: string
          max_stamps_per_visit: number
          reward: string
          shop_id: string
          stamps_needed: number
        }
        Insert: {
          id?: string
          max_stamps_per_visit?: number
          reward: string
          shop_id: string
          stamps_needed: number
        }
        Update: {
          id?: string
          max_stamps_per_visit?: number
          reward?: string
          shop_id?: string
          stamps_needed?: number
        }
        Relationships: [
          {
            foreignKeyName: "stamp_programs_shop_id_fkey"
            columns: ["shop_id"]
            isOneToOne: false
            referencedRelation: "shops"
            referencedColumns: ["id"]
          },
        ]
      }
      stamp_promos: {
        Row: {
          ends_at: string
          id: string
          multiplier: number
          name: string
          shop_id: string
          starts_at: string
        }
        Insert: {
          ends_at: string
          id?: string
          multiplier?: number
          name: string
          shop_id: string
          starts_at: string
        }
        Update: {
          ends_at?: string
          id?: string
          multiplier?: number
          name?: string
          shop_id?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "stamp_promos_shop_id_fkey"
            columns: ["shop_id"]
            isOneToOne: false
            referencedRelation: "shops"
            referencedColumns: ["id"]
          },
        ]
      }
      stamps: {
        Row: {
          amount: number
          created_at: string | null
          given_by: string | null
          id: string
          membership_id: string
          reason: string
          visit_id: string | null
        }
        Insert: {
          amount?: number
          created_at?: string | null
          given_by?: string | null
          id?: string
          membership_id: string
          reason?: string
          visit_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string | null
          given_by?: string | null
          id?: string
          membership_id?: string
          reason?: string
          visit_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "stamps_membership_id_fkey"
            columns: ["membership_id"]
            isOneToOne: false
            referencedRelation: "memberships"
            referencedColumns: ["id"]
          },
        ]
      }
      transfer_requests: {
        Row: {
          claimed_stamps: number
          code: string
          created_at: string | null
          expires_at: string
          id: string
          personal_card_id: string
          shop_id: string
          status: string
          user_id: string
        }
        Insert: {
          claimed_stamps: number
          code: string
          created_at?: string | null
          expires_at?: string
          id?: string
          personal_card_id: string
          shop_id: string
          status?: string
          user_id?: string
        }
        Update: {
          claimed_stamps?: number
          code?: string
          created_at?: string | null
          expires_at?: string
          id?: string
          personal_card_id?: string
          shop_id?: string
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "transfer_requests_personal_card_id_fkey"
            columns: ["personal_card_id"]
            isOneToOne: false
            referencedRelation: "personal_cards"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transfer_requests_shop_id_fkey"
            columns: ["shop_id"]
            isOneToOne: false
            referencedRelation: "shops"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      adjust_stamps: {
        Args: { p_change: number; p_member_number: string }
        Returns: number
      }
      balance: {
        Args: { m: Database["public"]["Tables"]["memberships"]["Row"] }
        Returns: number
      }
      card_history: {
        Args: { p_membership_id: string }
        Returns: {
          bonus: number
          change: number
          happened_at: string
          kind: string
          note: string
        }[]
      }
      complete_transfer: {
        Args: { p_code: string; p_confirmed: number; p_shop_id: string }
        Returns: number
      }
      give_stamps: {
        Args: { p_count?: number; p_member_number: string }
        Returns: number
      }
      hide_membership: { Args: { p_membership_id: string }; Returns: undefined }
      join_shop: { Args: { p_shop_id: string }; Returns: undefined }
      redeem_reward: { Args: { p_member_number: string }; Returns: number }
      request_redemption: {
        Args: { p_membership_id: string }
        Returns: {
          code: string
          id: string
        }[]
      }
      request_transfer: {
        Args: { p_personal_card_id: string; p_shop_id: string }
        Returns: {
          code: string
          id: string
        }[]
      }
      shop_activity: {
        Args: { p_days?: number; p_shop_id: string }
        Returns: {
          active_count: number
          repeat_count: number
        }[]
      }
      shop_customers: {
        Args: { p_shop_id: string }
        Returns: {
          balance: number
          from_paper: boolean
          joined_at: string
          last_visit: string
          member_number: string
          membership_id: string
          rewards: number
          visits: number
        }[]
      }
    }
    Enums: {
      shop_role: "owner" | "manager" | "staff"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      shop_role: ["owner", "manager", "staff"],
    },
  },
} as const
